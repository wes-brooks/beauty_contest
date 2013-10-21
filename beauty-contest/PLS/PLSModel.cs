using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;

using RCommon;
using RDotNet;
using RDotNet.NativeLibrary;

namespace PLS
{
	public class PLSModel : RModelInterface
	{
        private double threshold, regulatory, specificity;
        private string target;
        private List<string> names;
        private double[] actual, fitted, residuals;
        private Dictionary<string, double[]> data_dict;
        private DataFrame data_frame;
        private int num_predictors, ncomp, ncomp_max;
        private GenericVector model;

        public List<double> Actual { get { return actual.ToList(); } }
        public List<double> Fitted { get { return fitted.ToList(); } }
        public List<double> Residuals { get { return residuals.ToList(); } }
        public int Ncomp { get { return ncomp; } }
        public double Threshold { get { return threshold; } }
        public double Regulatory { get { return regulatory; } }
        public double Specificity { get { return specificity; } }
        public SymbolicExpression RModelObject { get { return model; } }

        public PLSModel()
        {
            RInterface.R.Evaluate("library(pls)");
        }


       	public void Create(Dictionary<string, double[]> data, string target, double regulatory=2.3711, double specificity=0.9)
		{
			this.regulatory = this.threshold = regulatory;

			//Get the data into R
			this.target = target;
			this.data_dict = data;
			this.data_frame = utils.DictionaryToR(data);
			this.num_predictors = this.data_dict.Keys.Count - 1;

			string validation;
			if (data.Values.First().Length > 2) {validation = "LOO";}
			else {validation = "none";}

			//Generate a PLS model in R. Special handling for only one predictor.
			string formula = utils.SanitizeVariableName(this.target) + "~.";
			RInterface.R.SetSymbol("d", this.data_frame);
			this.model = RInterface.R.Evaluate("plsr(" + formula + ", data=d, x=TRUE, validation='" + validation + "')").AsList();
			//r.Cleanup();

			//Get the number of columns from the validation step
			//(Might be fewer than the number of predictor variables if n<p)
            if (data.Values.First().Length > 2)
			{
				RInterface.R.SetSymbol("vars", this.model["validation"].AsList()["pred"]);
				double[] ncomp = RInterface.R.Evaluate("dim(vars)").AsNumeric().ToArray();
				this.ncomp_max = Convert.ToInt32(ncomp[2]);
				//r.Cleanup();
			}
			else {this.ncomp_max = 1;}

			//Use cross-validation to find the best number of components in the model.
			GetActual();
            if (data.Values.First().Length > 2) { CrossValidation(0); }//args);}
            else { this.ncomp = 1; }
			GetFitted();

			//Establish a decision threshold
            this.SetThreshold(specificity);
			//r.Cleanup();
		}


		public dynamic Extract(string model_part, dynamic container=null)
		{
			if (container==null) {container = this.model;}
            dynamic part;

			//use R's coef function to extract the model coefficients
			if (model_part == "coef")
			{
				RInterface.R.SetSymbol("model", this.model);
				part = (from x in RInterface.R.Evaluate("coef(object=model, ncomp=" + this.ncomp.ToString() + ", intercept=TRUE)").AsVector() select x).OfType<double>().ToList();
				//r.Cleanup();
			}
			//use R's MSEP function to estimate the variance.
			else if (model_part == "MSEP")
			{
				part = (from i in Enumerable.Range(0,this.fitted.Length) select Math.Pow(this.fitted[i] - this.actual[i], 2)).ToArray().Sum() / this.fitted.Length;
			}
			//use R's RMSEP function to estimate the standard error.
			else if (model_part == "RMSEP")
			{
				part = Math.Sqrt ((from i in Enumerable.Range(0,this.fitted.Length) select Math.Pow(this.fitted[i] - this.actual[i], 2)).ToArray().Sum() / this.fitted.Length);
			}

			//Get the variable names, ordered as R sees them.
			else if (model_part == "names")
			{
				part = new List<string> ();
				part.Add ("Intercept");
				part.AddRange(this.data_dict.Keys);
				try {part.Remove(this.target);}
				catch {}
			}

			//otherwise, go to the data structure itself
			else {part = container[model_part];}

			return(part);
		}


		public List<double[]> PredictValues(Dictionary<string, double[]> Data)
		{
			DataFrame data_frame = utils.DictionaryToR(Data);

			RInterface.R.SetSymbol("model", this.model);
			RInterface.R.SetSymbol("d", data_frame);
			double[] pred = RInterface.R.Evaluate("predict(object=model, newdata=d)").AsNumeric().ToArray();
			//r.Cleanup();

			//Reshape the vector of predictions
			int columns = Math.Min(this.num_predictors, this.ncomp_max);
			int rows = pred.Length / columns;

			List<double[]> predictions = new List<double[]>();
			for (int k=0; k<columns; k++)
			{
				int b = k * rows;
                predictions.Add(pred.Skip(b).Take(rows).ToArray());
			}

			return(predictions);
		}


		public int[] PredictExceedances(Dictionary<string, double[]> Data)
		{
			List<double[]> prediction = PredictValues(Data);
			int[] exceed = (from p in prediction [this.ncomp - 1] select p >= this.threshold ? 1 : 0).ToArray ();
			return(exceed);
		}


		public List<double> PredictExceedanceProbability(Dictionary<string, double[]> Data, double Threshold=Double.NaN)
		{
            if (Double.IsNaN(Threshold)) {Threshold = this.threshold;}

			//Find the number of standard deviations above or below the threshold:
			double[] prediction = PredictValues(Data)[this.ncomp-1];
			double se = Extract("RMSEP");
			double[] adjusted = (from x in prediction select (x-Threshold)/se).ToArray<double>();

			//Compute the exceedance probability:
			NumericVector q = RInterface.R.CreateNumericVector(adjusted).AsNumeric();
			RInterface.R.SetSymbol("quantiles", q);
			double[] prob = (from x in RInterface.R.Evaluate("pnorm(q=quantiles)").AsNumeric().ToArray() select 100*x).ToArray<double>();

			//Cleanup and return
			//r.Cleanup();
			return(prob.ToList());
		}


        public List<double> PredictExceedanceProbability(DataTable Data, double Threshold = Double.NaN)
        {
            HeadersAndData hd = utils.DotNetToArray(Data);
            List<string> headers = hd.headers.ToList();
            List<double[]> columns = hd.data;
            Dictionary<string, double[]> datadict = headers.Zip(columns, (k, v) => new { Key = k, Value = v }).ToDictionary(x => x.Key, x => x.Value);

            if (Double.IsNaN(Threshold)) { Threshold = this.threshold; }

            //Find the number of standard deviations above or below the threshold:
            double[] prediction = PredictValues(datadict)[this.ncomp - 1];
            double se = Extract("RMSEP");
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
            Dictionary<string, double[]> datadict = headers.Zip(columns, (k,v) => new {Key=k, Value=v}).ToDictionary(x => x.Key, x => x.Value);
            
            List<double[]> prediction = PredictValues(datadict);
			return(prediction[this.ncomp-1].ToList());
		}


        public List<double> Predict(Dictionary<string, double[]> Data)
        {
            List<double[]> prediction = PredictValues(Data);
            return (prediction[this.ncomp - 1].ToList());
        }


		public void CrossValidation(int cv_method=0)
		{
			//Select ncomp by the requested CV method
			GenericVector validation = this.model["validation"].AsList();

			//method 0: select the fewest components with PRESS within 1 stdev of the least PRESS (by the bootstrap)
			if (cv_method == 0) //Use the bootstrap to find the standard deviation of the MSEP
			{
				//Get the leave-one-out CV error from R:
				int columns = Math.Min(this.num_predictors, this.ncomp_max);
				double[] pred = validation["pred"].AsNumeric().ToArray();
				int rows = pred.Length / columns;
				List<double[]> cv = new List<double[]>();
				for (int k=0; k<columns; k++)
				{
					int b = k * rows;
                    cv.Add(pred.Skip(b).Take(rows).ToArray());
				}

				double[] PRESS = (from i in Enumerable.Range(0, columns) select (from j in Enumerable.Range(0, rows) select Math.Pow(cv[i][j]-this.actual[j], 2)).ToArray().Sum()).ToArray();
				int ncomp = (from i in Enumerable.Range(0, PRESS.Length) where PRESS[i]==PRESS.Min() select i).ToArray()[0];

				double[] cv_squared_error = (from j in Enumerable.Range(0, rows) select Math.Pow(cv[ncomp][j]-this.actual[j], 2)).ToArray();
				int[] sample_space = Enumerable.Range(0, rows).OfType<int>().ToArray();
				List<double> PRESS_stdev = new List<double>();

				for (int i=0; i<100; i++)
				{
					List<double> PRESS_bootstrap = new List<double>();

					for (int j=0; j<100; j++)
					{
						PRESS_bootstrap.Add((from k in sample_space select cv_squared_error[Convert.ToInt32(Math.Floor(utils.rng.NextDouble()*rows))]).ToArray().Sum());
					}

					PRESS_stdev.Add(utils.std(PRESS_bootstrap));
				}

				double med_stdev = utils.Median(PRESS_stdev.ToArray());

				//Maximum allowable PRESS is the minimum plus one standard deviation
				int[] good_ncomp = (from i in Enumerable.Range(0, PRESS.Length) where PRESS[i] < PRESS.Min() + med_stdev select i).ToArray();
				this.ncomp = good_ncomp.Min() + 1;
			}

			//method 1: select the fewest components w/ PRESS less than the minimum plus a 4% of the range
			if (cv_method==1)
			{
				//PRESS stands for predicted error sum of squares
				double PRESS0 = Convert.ToDouble(validation["PRESS0"].AsVector()[0]);
				double[] PRESS = validation["PRESS"].AsNumeric().OfType<double>().ToArray();

				//the range is the difference between the greatest and least PRESS values
				double PRESS_range = Math.Abs(PRESS0 - PRESS.Min());

				//Maximum allowable PRESS is the minimum plus a fraction of the range.
				double max_CV_error = PRESS.Min() + PRESS_range/25;
				int[] good_ncomp = (from i in Enumerable.Range(0, PRESS.Length) where PRESS[i] < max_CV_error select i).ToArray();

				//choose the most parsimonious model that satisfies that criterion
				this.ncomp = good_ncomp.Min() + 1;
			}
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

            return (new double[2] { dblThreshold, dblSpecificity });
        }


		public void GetActual()
		{
			//Get the fitted counts from the model.
			int columns = Math.Min(this.num_predictors, this.ncomp_max);
			double[] fitted = this.model["fitted.values"].AsNumeric().ToArray();
			int rows = fitted.Length / columns;

			List<double[]> ff = new List<double[]>();
			for (int k=0; k<columns; k++)
			{
				int b = k * rows;				
				ff.Add(fitted.Skip(b).Take(rows).ToArray());
			}
			fitted = ff[0];

			//Recover the actual counts by adding the residuals to the fitted counts.
			double[] residuals = this.model["residuals"].AsNumeric().ToArray();
			List<double[]> rr = new List<double[]>();
			for (int k=0; k<columns; k++)
			{
				int b = k * rows;
                rr.Add(residuals.Skip(b).Take(rows).ToArray());
			}
			residuals = rr[0];

			this.actual = (from i in Enumerable.Range(0, fitted.Length) select fitted[i] + residuals[i]).ToArray();
		}


		public void GetFitted()
		{
			/*try {ncomp = Convert.ToInt32(args["ncomp"]);}
			catch (KeyError)
			{
				try {ncomp = this.ncomp;}
				catch (AttributeError) {ncomp=1;}
			}*/

			//Get the fitted counts from the model so we can compare them to the actual counts.
			int columns = Math.Min(this.num_predictors, this.ncomp_max);
			double[] fitted = this.model["fitted.values"].AsVector().OfType<double>().ToArray();
			int rows = fitted.Length / columns;

			List<double[]> ff = new List<double[]>();
			for (int k=0; k<columns; k++)
			{
				int b = k * rows;
				ff.Add(fitted.Skip(b).Take(rows).ToArray());
			}
			fitted = ff[this.ncomp-1];

			this.fitted = fitted;
			this.residuals = (from i in Enumerable.Range(0,fitted.Length) select this.actual[i] - this.fitted[i]).ToArray();
		}


		public Dictionary<string, double> GetInfluence()
		{
			//Get the covariate names
			this.names = this.data_dict.Keys.ToList<string>();
			this.names.Remove(this.target);

			//Now get the model coefficients from R.
			List<double> coefficients = Extract("coef");

			//Get the standard deviations (from the data_dictionary) and package the influence in a dictionary.
			List<double> raw_influence = new List<double>();

			for (int i=0; i<names.Count; i++)
			{
				double standard_deviation = utils.std( this.data_dict[this.names[i]] );
				raw_influence.Add(Math.Abs(standard_deviation * coefficients[i+1]));
			}

			Dictionary<string, double> influence = this.names.Zip((from x in raw_influence select x / raw_influence.Sum()).ToArray(), (key, value) => new {key, value})
				.ToDictionary(x => x.key, x => x.value);
			return(influence);
		}

		
		public double[] Count()
		{																														
			//Count the number of true positives, true negatives, false positives, and false negatives.
			GetActual();
			GetFitted();
			
			//initialize counts to zero:
			int t_pos = 0;
			int t_neg = 0;
			int f_pos = 0;
			int f_neg = 0;

			for (int obs=0; obs<this.fitted.Count(); obs++)
			{
				if (this.fitted[obs] >= this.threshold)
				{
					if (this.actual[obs] >= 2.3711) {t_pos += 1;}
					else {f_pos += 1;}
				}
				else
				{
					if (this.actual[obs] >= 2.3711) {f_neg += 1;}
					else {t_neg += 1;}
				}
			}
			return(new double[] {t_pos, t_neg, f_pos, f_neg});
		}


		public string GetModelExpression()
        {
            //Return a list of the predictor variables that are used in this model.
            List<string> predictors = Extract("names");

            string expression = ""; // target + " = ";
            if (predictors.Count > 1)  { expression += String.Join(" + ", predictors.Skip(1)); }
            else { expression += predictors.FirstOrDefault(); }

            return(expression);
        }
	}
}

