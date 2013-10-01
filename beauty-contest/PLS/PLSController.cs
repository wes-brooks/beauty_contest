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
    public class PLSController : RControllerInterface
    {
        public void Validate(DataTable Data, string Target, double Threshold, double Specificity, int Folds, ModelProgressDelegate ProgressCallback, ModelCancelledDelegate CancellationCallback, ModelValidationCompleteDelegate CompletionCallback)
        {
            //Creates a PLS model and tests its performance with cross-validation.
            HeadersAndData hd = utils.DotNetToArray(Data);
            string[] headers = hd.headers;
            List<double[]> datalist = hd.data;
            double regulatory = Threshold;

            //randomly assign the data to cross-validation folds
            if (Folds == null) { Folds = 5; }
            int[] fold = utils.Partition(datalist, Folds);
            List<double[]> columns = new List<double[]>();

            for (int i = 0; i < Data.Columns.Count; i++)
            {
                columns.Add((from DataRow row in Data.Rows select Convert.ToDouble(row.ItemArray[i])).ToArray());
            }

            Dictionary<string, double[]> data_dict = headers.Zip(columns, (k, v) => new { Key = k, Value = v }).ToDictionary(x => x.Key, x => x.Value);

            //Make a model for each fold and validate it.
            List<Dictionary<string, List<double>>> results = new List<Dictionary<string, List<double>>>();
            for (int f = 1; f <= Folds; f++)
            {
                //if (canceltoken != null) { if (canceltoken.IsCancellationRequested) { break; } }

                List<double[]> model_data = (from i in Enumerable.Range(0, Data.Rows.Count) where fold[i] != f select Data.Rows[i].ItemArray.OfType<double>().ToArray()).ToList();
                List<double[]> validation_data = (from i in Enumerable.Range(0, Data.Rows.Count) where fold[i] == f select Data.Rows[i].ItemArray.OfType<double>().ToArray()).ToList();

                Dictionary<string, double[]> model_dict = headers.Zip(from i in Enumerable.Range(0, model_data[0].Length) select (from row in model_data select row[i]).ToArray<double>(), (k, v) => new { Key = k, Value = v }).ToDictionary(x => x.Key, x => x.Value);
                Dictionary<string, double[]> validation_dict = headers.Zip(from i in Enumerable.Range(0, validation_data[0].Length) select (from row in validation_data select row[i]).ToArray<double>(), (k, v) => new { Key = k, Value = v }).ToDictionary(x => x.Key, x => x.Value);

                PLSModel m = new PLSModel();
                m.Create(data: model_dict, target: Target, regulatory: regulatory, specificity: Specificity);

                ProgressCallback(Message: "Model " + f.ToString() + " of " + Folds.ToString() + " built.", Progress: (f - 0.5) / Folds);

                List<double> predictions = m.Predict(validation_dict);
                double[] validation_actual = validation_dict[Target];
                int[] exceedance = (from x in validation_actual select x > regulatory ? 1 : 0).ToArray<int>();

                List<double> fitted = m.Fitted;
                List<double> actual = m.Actual;

                //We no longer need to hang on to the model object (we've got all the info we need)
                m = null;

                double[] candidates = (from i in Enumerable.Range(0, fitted.Count) where actual[i] < regulatory select fitted[i]).ToArray();
                int num_candidates = candidates.Length;

                List<double> spec = new List<double>();
                List<double> sensitivity = new List<double>();
                List<double> thresholds = new List<double>();
                List<double> tpos = new List<double>();
                List<double> tneg = new List<double>();
                List<double> fpos = new List<double>();
                List<double> fneg = new List<double>();
                int total = model_data.Count;
                int non_exceedances = exceedance.Length - exceedance.Sum();
                int exceedances = exceedance.Sum();

                foreach (double prediction in predictions)
                {
                    double tp = (from i in Enumerable.Range(0, predictions.Count) where predictions[i] >= prediction && validation_actual[i] >= regulatory select i).Count(); //.ToArray().Length;
                    double fp = (from i in Enumerable.Range(0, predictions.Count) where predictions[i] >= prediction && validation_actual[i] < regulatory select i).Count(); //.ToArray().Length;
                    double tn = (from i in Enumerable.Range(0, predictions.Count) where predictions[i] < prediction && validation_actual[i] < regulatory select i).Count(); //.ToArray().Length;
                    double fn = (from i in Enumerable.Range(0, predictions.Count) where predictions[i] < prediction && validation_actual[i] >= regulatory select i).Count(); //.ToArray().Length;

                    tpos.Add(tp);
                    fpos.Add(fp);
                    tneg.Add(tn);
                    fneg.Add(fn);

                    double candidate_threshold;

                    if (num_candidates > 0)
                    {                    
                        try { candidate_threshold = (from x in candidates where x <= prediction select x).ToArray().Max(); }
                        catch { candidate_threshold = candidates.Min(); }

                        spec.Add(Convert.ToDouble((from i in Enumerable.Range(0, fitted.Count) where actual[i] <= regulatory && fitted[i] <= candidate_threshold select i).Count()) / Convert.ToDouble(num_candidates));
                    }
                    else
                    {
                        spec.Add(1);
                        candidate_threshold = predictions.Min() * 0.99;
                    }

                    if (actual.Count > num_candidates) { sensitivity.Add(Convert.ToDouble((from i in Enumerable.Range(0, fitted.Count) where actual[i] > regulatory && fitted[i] > candidate_threshold select i).Count()) / Convert.ToDouble(actual.Count - num_candidates));}
                    else { sensitivity.Add(1); }

                    //the first candidate threshold that would be below this threshold
                    try { thresholds.Add((from x in fitted where x <= prediction select x).ToArray().Max()); }
                    catch { thresholds.Add(fitted.Max()); }
                }

                ProgressCallback(Message: "Model " + f.ToString() + " of " + Folds + " validated.", Progress: Convert.ToDouble(f) / Folds);

                Dictionary<string, List<double>> result = new Dictionary<string, List<double>>{
                    {"threshold", thresholds},
                    {"sensitivity", sensitivity},
                    {"specificity", spec},
                    {"tpos", tpos},
                    {"tneg", tneg},
                    {"fpos", fpos},
                    {"fneg", fneg} };
                results.Add(result);
            }

            PLSModel model = new PLSModel();
            model.Create(data: data_dict, target: Target, regulatory: regulatory, specificity: Specificity);
            CompletionCallback(Result: new ValidationAndModel(results, model));
        }
    }
}
