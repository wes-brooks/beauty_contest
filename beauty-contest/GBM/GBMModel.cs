using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;

using RCommon;
using RDotNet;
using RDotNet.NativeLibrary;

namespace GBM
{
    public class GBMModel : RModelInterface
    {
        private double threshold, regulatory, specificity, shrinkage, fraction;
        private string target;
        private List<string> names, vars;
        private double[] actual, fitted, residuals, cost, weights;
        private Dictionary<string, double[]> data_dict;
        private DataFrame data_frame;
        private int num_predictors, iterations, depth, minobsinnode, folds, trees;
        private GenericVector model;

        public List<double> Actual { get { return actual.ToList(); } }
        public List<double> Fitted { get { return fitted.ToList(); } }
        public List<double> Residuals { get { return residuals.ToList(); } }
        public double Threshold { get { return threshold; } }
        public double Regulatory { get { return regulatory; } }
        public double Specificity { get { return specificity; } }
        public SymbolicExpression RModelObject { get { return model; } }

        public GBMModel()
        {
            RInterface.R.Evaluate("library(gbm)");
        }
        
        
        public void Create(Dictionary<string, double[]> data, string target, double regulatory = 2.3711, int iterations = 10000, double[] cost = null, double specificity = 0.9, int depth = 5, int minobsinnode = 5, double shrinkage = 0.001, double fraction = 0.5, int folds = 5, string weights = "none")
        {
            this.regulatory = this.threshold = regulatory;
            this.iterations = iterations;
            this.cost = cost ?? new double[] { 1, 1 };
            this.depth = depth;
            this.minobsinnode = minobsinnode;
            this.shrinkage = shrinkage;
            this.fraction = fraction;
            this.folds = folds;
            this.target = target;
            this.data_dict = data;
            this.actual = data[target];

            //GBM requires that nTrain * fraction > minobsinnode:
            int ntrain;
            if (folds > 1) { ntrain = (int)Math.Floor(Convert.ToDouble(data.Values.First().Length) * (folds - 1) / folds); }
            else { ntrain = data.Values.First().Length; }
            if ((ntrain-1) * fraction <= 2*minobsinnode)
            {
                this.folds = folds = 0;
                ntrain = data.Values.First().Length;
                this.minobsinnode = minobsinnode = 3;
                this.fraction = fraction = Math.Min(1.0, Math.Max(0.5, Convert.ToDouble(2 * minobsinnode) / (ntrain-1)));
            }
            
            //Get the data into R
            this.data_frame = utils.DictionaryToR(data);
            this.num_predictors = this.data_dict.Keys.Count - 1;

            //Check to see if a weighting method has been specified in the function's arguments 
            this.weights = AssignWeights(weights);

            //Put the data and weights into R
            string formula = utils.SanitizeVariableName(this.target) + "~.";
            RInterface.R.SetSymbol("d", this.data_frame);
            NumericVector wt = RInterface.R.CreateNumericVector(this.weights);
            RInterface.R.SetSymbol("w", wt);

            //Generate a GBM model in R. Special handling for only one predictor.
            this.model = RInterface.R.Evaluate("gbm(" + formula + ", distribution='gaussian', data=d, weights=w, interaction.depth=" + depth.ToString() + ", shrinkage=" + shrinkage.ToString() + ", n.trees=" + iterations.ToString() + ", bag.fraction=" + fraction.ToString() + ", n.minobsinnode=" + minobsinnode.ToString() + ", cv.folds=" + folds.ToString() + ")").AsList();

            //Find the best number of iterations for predictive performance. Prefer to use CV.
            string method;
            if (folds > 1) { method = "cv"; }
            else { method = "OOB"; }

            RInterface.R.SetSymbol("model", this.model);
            this.trees = Convert.ToInt32(RInterface.R.Evaluate("gbm.perf(object=model, plot.it=FALSE, method='" + method + "')").AsNumeric().ToArray()[0]);

            GetFitted();
            SetThreshold(specificity);
        }


        private double[] AssignWeights(string method)
        {
            //Weight the observations in the training set based on their distance from the threshold.
            double std = utils.std(this.actual);
            List<double> deviation = (from x in this.actual select (x - this.regulatory) / std).ToList();
            double[] weights;

            //Integer weighting: weight is the observation's rounded-up whole number of standard deviations from the threshold.
            if (method.ToLower()[0] == 'd' || method.ToLower()[0] == 'i')
            {
                weights = Enumerable.Repeat(1.0, deviation.Count).ToArray();
                List<int> breaks = Enumerable.Range((int)(Math.Floor(deviation.Min())), (int)(Math.Ceiling(deviation.Max()))).ToList();

                foreach (int i in breaks)
                {
                    //Find all the observations that meet both criteria simultaneously
                    List<int> rows = (from j in Enumerable.Range(0, deviation.Count) where deviation[j] >= i && deviation[j] < i + 1 select j).ToList();

                    //Decide how many times to replicate each slice of data
                    int replicates;
                    if (i <= 0)
                        replicates = 0;
                    else
                        replicates = 2 * i;

                    weights = (from k in Enumerable.Range(0, weights.Length) select rows.Contains(k) ? replicates + 1 : weights[k]).ToArray();
                }
            }

            //Continuous weighting: weight is the observation's distance (in standard deviations) from the threshold.      
            else if (method.ToLower()[0] == 'd')
            {
                weights = (from i in Enumerable.Range(0, deviation.Count) select Math.Abs(deviation[i])).ToArray();
            }

            //put more weight on exceedances
            else if (method.ToLower()[0] == 'c')
            {
                //initialize all weights to one.
                weights = Enumerable.Repeat(1.0, deviation.Count).ToArray();

                //apply weight to the exceedances
                List<int> rows = (from i in Enumerable.Range(0, deviation.Count) where deviation[i] > 0 select i).ToList();
                weights = (from i in Enumerable.Range(0, weights.Length) select rows.Contains(i) ? this.cost[1] : weights[i]).ToArray();

                //apply weight to the non-exceedances
                rows = (from i in Enumerable.Range(0, deviation.Count) where deviation[i] <= 0 select i).ToList();
                weights = (from i in Enumerable.Range(0, weights.Length) select rows.Contains(i) ? this.cost[0] : weights[i]).ToArray();
            }

            //put more weight on exceedances AND downweight near the threshold
            else if (method.ToLower()[0] == 'b')
            {
                //initialize all weights to one.
                weights = Enumerable.Repeat(1.0, deviation.Count).ToArray();

                //apply weight to the exceedances
                List<int> rows = (from i in Enumerable.Range(0, deviation.Count) where deviation[i] > 0 select i).ToList();
                weights = (from i in Enumerable.Range(0, weights.Length) select rows.Contains(i) ? this.cost[1] : weights[i]).ToArray();

                //apply weight to the non-exceedances
                rows = (from i in Enumerable.Range(0, deviation.Count) where deviation[i] <= 0 select i).ToList();
                weights = (from i in Enumerable.Range(0, weights.Length) select rows.Contains(i) ? this.cost[0] : weights[i]).ToArray();

                //downweight near the threshold
                rows = (from i in Enumerable.Range(0, deviation.Count) where Math.Abs(deviation[i]) <= 0.25 select i).ToList();
                weights = (from i in Enumerable.Range(0, weights.Length) select rows.Contains(i) ? weights[i] / 4 : weights[i]).ToArray();
            }

            //No weights: all weights are one.
            else { weights = Enumerable.Repeat(1.0, deviation.Count).ToArray(); }

            return (weights);
        }


        public dynamic Extract(string model_part, dynamic container = null)
        {
            if (container == null) { container = this.model; }
            dynamic part;

            //Get the variable names, ordered as R sees them.
            if (model_part == "names")
            {
                part = new List<string>();
                part.Add("Intercept");
                part.AddRange(this.data_dict.Keys);
                try { part.Remove(this.target); }
                catch { }
            }

            //otherwise, go to the data structure itself
            else { part = container[model_part]; }

            return (part);
        }


        public double[] PredictValues(Dictionary<string, double[]> Data)
        {
            DataFrame data_frame = utils.DictionaryToR(Data);

            RInterface.R.SetSymbol("model", this.model);
            RInterface.R.SetSymbol("d", data_frame);
            double[] predictions = RInterface.R.Evaluate("predict(object=model, newdata=d, n.trees=" + this.trees.ToString() + ")").AsNumeric().ToArray();

            return (predictions);
        }


        public int[] PredictExceedances(Dictionary<string, double[]> Data)
        {
            double[] predictions = PredictValues(Data);
            int[] exceed = (from p in predictions select p >= this.threshold ? 1 : 0).ToArray();
            return (exceed);
        }


        public List<double> PredictExceedanceProbability(Dictionary<string, double[]> Data, double Threshold = Double.NaN)
        {
            if (Double.IsNaN(Threshold)) { Threshold = this.threshold; }

            //Find the number of standard deviations above or below the threshold:
            double[] prediction = PredictValues(Data);
            double se = Math.Sqrt((from x in this.residuals select Math.Pow(x, 2)).ToArray().Sum() / this.residuals.Length);
            double[] adjusted = (from x in prediction select (x - Threshold) / se).ToArray<double>();

            //Compute the exceedance probability:
            NumericVector q = RInterface.R.CreateNumericVector(adjusted).AsNumeric();
            RInterface.R.SetSymbol("quantiles", q);
            double[] prob = (from x in RInterface.R.Evaluate("pnorm(q=quantiles)").AsNumeric().ToArray() select 100 * x).ToArray<double>();

            //Cleanup and return
            //r.Cleanup();
            return (prob.ToList());
        }


        public List<double> PredictExceedanceProbability(DataTable Data, double Threshold = Double.NaN)
        {
            HeadersAndData hd = utils.DotNetToArray(Data);
            List<string> headers = hd.headers.ToList();
            List<double[]> columns = hd.data;
            Dictionary<string, double[]> datadict = headers.Zip(columns, (k, v) => new { Key = k, Value = v }).ToDictionary(x => x.Key, x => x.Value);

            if (Double.IsNaN(Threshold)) { Threshold = this.threshold; }

            //Find the number of standard deviations above or below the threshold:
            double[] prediction = PredictValues(datadict);
            double se = Math.Sqrt((from x in this.residuals select Math.Pow(x, 2)).ToArray().Sum() / this.residuals.Length);
            double[] adjusted = (from x in prediction select (x - Threshold) / se).ToArray<double>();

            //Compute the exceedance probability:
            NumericVector q = RInterface.R.CreateNumericVector(adjusted).AsNumeric();
            RInterface.R.SetSymbol("quantiles", q);
            double[] prob = (from x in RInterface.R.Evaluate("pnorm(q=quantiles)").AsNumeric().ToArray() select 100 * x).ToArray<double>();

            //Cleanup and return
            //r.Cleanup();
            return (prob.ToList());
        }


        public List<double> Predict(DataTable Data)
        {
            HeadersAndData hd = utils.DotNetToArray(Data);
            List<string> headers = hd.headers.ToList();
            List<double[]> columns = hd.data;
            Dictionary<string, double[]> datadict = headers.Zip(columns, (k, v) => new { Key = k, Value = v }).ToDictionary(x => x.Key, x => x.Value);

            double[] prediction = PredictValues(datadict);
            return (prediction.ToList());
        }


        public List<double> Predict(Dictionary<string, double[]> Data)
        {
            double[] prediction = PredictValues(Data);
            return (prediction.ToList());
        }


        public void SetThreshold(double Specificity = 0.9)
        {
            double[] thresholding = GetThreshold(Specificity);

            this.threshold = thresholding[0];
            this.specificity = thresholding[1];
        }


        public double[] GetThreshold(double Specificity = 0.9)
        {
            double dblThreshold;
            double dblSpecificity = Specificity;
            if (this.fitted == null) { GetFitted(); }

            //Decision threshold is the [specificity] quantile of the fitted values for non-exceedances in the training set.
            try
            {
                double[] non_exceedances = (from i in Enumerable.Range(0, this.fitted.Length) where this.actual[i] <= this.regulatory select this.fitted[i]).ToArray<double>();
                dblThreshold = utils.Quantile(non_exceedances, dblSpecificity);
                dblSpecificity = Convert.ToDouble((from x in non_exceedances where x <= dblThreshold select x).ToArray().Length) / Convert.ToDouble(non_exceedances.Length);
            }
            //This error should only happen if somehow there are no non-exceedances in the training data.
            catch
            {
                dblThreshold = this.regulatory;
            }

            return(new double[2] {dblThreshold, dblSpecificity});
        }


        public void GetFitted()
        {
            RInterface.R.SetSymbol("model", this.model);
            RInterface.R.SetSymbol("newdata", this.data_frame);
            this.fitted = RInterface.R.Evaluate("predict(object=model, n.trees=" + this.trees.ToString() + ", newdata=newdata)").AsNumeric().ToArray();
            this.residuals = (from i in Enumerable.Range(0, fitted.Length) select this.actual[i] - this.fitted[i]).ToArray();
        }


        public List<int> Discretize(List<double> raw)
        {
            //Label observations as above or below the threshold.
            List<int> discretized = (from x in raw select x > this.regulatory ? 1 : 0).ToList();
            return (discretized);
        }


        public Dictionary<string, double> GetInfluence()
        {
            this.names = this.data_dict.Keys.ToList();
            this.names.Remove(this.target);

            RInterface.R.SetSymbol("m", this.model);
            RInterface.R.Evaluate("rel.inf = relative.influence(object=m, n.trees=" + this.trees.ToString() + ")");
            RInterface.R.Evaluate("rel.inf[rel.inf<0] = 0");
            RInterface.R.Evaluate("i = order(-rel.inf)");
            RInterface.R.Evaluate("rel.inf = 100*rel.inf/sum(rel.inf)");
            GenericVector summary = RInterface.R.Evaluate("data.frame(var=m$var.names[i], rel.inf=rel.inf[i])").AsList();

            List<int> indx = (from i in summary[0].AsVector() select Convert.ToInt32(i)).ToList();
            RInterface.R.SetSymbol("obj", summary[0]);
            DynamicVector levels = RInterface.R.Evaluate("levels(x=obj)").AsVector();

            List<double> influence = summary[1].AsNumeric().ToList();
            List<string> vars = (from i in indx select levels[i - 1].ToString()).ToList();

            //Create a dictionary with all the influences and a list of those variables with influence greater than 1%.
            Dictionary<string, double> result = this.names.Zip(influence, (k, v) => new { Key = k, Value = v }).ToDictionary(x => x.Key, x => x.Value);
            this.vars = (from k in Enumerable.Range(0, vars.Count) where influence[k] > 5 select vars[k]).ToList();
            return (result);
        }


        public double[] Count()
        {
            //Count the number of true positives, true negatives, false positives, and false negatives.
            GetFitted();

            //initialize counts to zero:
            int t_pos = 0;
            int t_neg = 0;
            int f_pos = 0;
            int f_neg = 0;

            for (int obs = 0; obs < this.fitted.Count(); obs++)
            {
                if (this.fitted[obs] >= this.threshold)
                {
                    if (this.actual[obs] >= 2.3711) { t_pos += 1; }
                    else { f_pos += 1; }
                }
                else
                {
                    if (this.actual[obs] >= 2.3711) { f_neg += 1; }
                    else { t_neg += 1; }
                }
            }
            return (new double[] { t_pos, t_neg, f_pos, f_neg });
        }


        public string GetModelExpression()
        {
            //Return a list of the predictor variables that are used in this model.
            List<string> predictors = Extract("names");

            string expression = ""; // target + " = ";
            if (predictors.Count > 1) { expression += String.Join(" + ", predictors.Skip(1)); }
            else { expression += predictors.FirstOrDefault(); }

            return (expression);
        }
    }
}

