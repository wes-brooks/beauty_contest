using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Reflection;
using System.IO;
using System.Data;

using RCommon;
using RDotNet;
using RDotNet.NativeLibrary;


namespace beauty_contest
{
    partial class Program
    {
        public static void Summarize(ValidationAndModel Result)
        {
            List<List<double>> Sorted = SpecificityChart(Result);
        }


		public static double AreaUnderROC(ValidationAndModel Result)
		{
			Double threshold = raw["threshold"];
			Int32 numfolds = raw["train"].Count();
			List<double> tp = new List<double>();
			List<double> tn = new List<double>();
			List<double> fp = new List<double>();
			List<double> fn = new List<double>();
			List<double> sp = new List<double>();

			for (int fold=0; fold<numfolds; fold++)
			{
				List<double> tpos = new List<double>();
				List<double> tneg = new List<double>();
				List<double> fpos = new List<double>();
				List<double> fneg = new List<double>();
				List<double> spec = new List<double>();
				lenfold = raw["train"][fold].Count();
				lenpred = raw["validate"][fold].Count();

				training_exc = [raw["train"][fold][i] > threshold for i in range(lenfold)];
				training_nonexc = [raw["train"][fold][i] <= threshold for i in range(lenfold)];
				thresholds = [raw["fitted"][fold][i] for i in range(lenfold) if training_nonexc[i] == True];
				order = sorted(range(len(thresholds)), key=thresholds.__getitem__);

				for (int i=0; i<order.Count(); i++)
				{
					k = order[i];

					spec.append(len([i for i in range(len(thresholds)) if thresholds[i] <= thresholds[k]]) / float(len(thresholds)));
					tpos.append(len([i for i in range(lenpred) if raw["validate"][fold][i] > threshold and raw["predicted"][fold][i] > thresholds[k]]));
					tneg.append(len([i for i in range(lenpred) if raw["validate"][fold][i] <= threshold and raw["predicted"][fold][i] <= thresholds[k]]));
					fpos.append(len([i for i in range(lenpred) if raw["validate"][fold][i] <= threshold and raw["predicted"][fold][i] > thresholds[k]]));
					fneg.append(len([i for i in range(lenpred) if raw["validate"][fold][i] > threshold and raw["predicted"][fold][i] <= thresholds[k]]));
				}
				tp.append(tpos);
				tn.append(tneg);
				fp.append(fpos);
				fn.append(fneg);
				sp.append(spec);
			}

			List<double> specs = new List<double>();
			[specs.extend(s) for s in sp];
			specs = list(set(specs));
			specs.sort();

			List<double> tpos = new List<double>();
			List<double> tneg = new List<double>();
			List<double> fpos = new List<double>();
			List<double> fneg = new List<double>();
			List<double> spec = new List<double>();

			int folds = tp.Count();

			for (int j=0; j<specs.Count(); j++)
			{
				Double s = specs[j];
				tpos.append(0);
				tneg.append(0);
				fpos.append(0);
				fneg.append(0);
				spec.append(s);

				for (int f=0; f<folds.Count(); f++)
				{
					indx = [i for i in range(len(sp[f])) if sp[f][i] >= s];
					indx = sorted(indx, key=sp[f].__getitem__)[0];

					tpos[-1] += tp[f][indx];
					tneg[-1] += tn[f][indx];
					fpos[-1] += fp[f][indx];
					fneg[-1] += fn[f][indx];
				}
			}

			//Begin by assuming that we call every observation an exceedance
			area = 0;
			spec_last = 0;
			sens_last = 1;

			for (int k=0; k<specs.Count(); k++)
			{
				sens = tpos[k] / (tpos[k] + fneg[k]);
				sp = tneg[k] / (tneg[k] + fpos[k]);
				area += (sp - spec_last) * sens;
				
				sens_last = copy.copy(sens);
				spec_last = copy.copy(sp);
			}

			return area;
		}



        public static List<List<double>> SpecificityChart(ValidationAndModel Result)
        {
            //Produces a list of lists that Virtual Beach turns into a chart of performance in prediction as we sweep the specificity parameter.
            List<List<double>> Sorted = new List<List<double>>();
            List<double> specificities = new List<double>();

            foreach (Dictionary<String, List<Double>> fold in Result.Validation)
            {
                specificities.Union(fold["specificity"]);
            }
            specificities.Sort();
    
            List<double> spec = new List<double>();
            List<double> sens = new List<double>();
            List<double> tpos = new List<double>();
            List<double> tneg = new List<double>();
            List<double> fpos = new List<double>();
            List<double> fneg = new List<double>();
    
            for (int i=0; i<specificities.Count; i++)
            {
                Double specificity = specificities[i];

                tpos.Add(0);
                tneg.Add(0);
                fpos.Add(0);
                fneg.Add(0);
                spec.Add(specificity);
        
                foreach (Dictionary<String, List<Double>> fold in Result.Validation)
                {
                    List<Int32> indx = (from k in Enumerable.Range(0,fold["specificity"].Count) where fold["specificity"][k] >= specificity select k).ToList<Int32>();
                    List<Double> ss = (from k in indx select fold["specificity"][k]).ToList<Double>();
                    Int32 last = tpos.Count;

                    if (indx.Count > 0)
                    {
                        int j = indx[ss.IndexOf(ss.Min())];  //sorted(range(len(indx)), key = indx.__getitem__)[0]; //argmin of indx
                                    
                        tpos[i] += fold["tpos"][j];
                        fpos[i] += fold["fpos"][j];
                        tneg[i] += fold["tneg"][j];
                        fneg[i] += fold["fneg"][j];
                    }
                    else
                    {
                        tpos[i] = tpos[i] + fold["tpos"][0] + fold["fneg"][0]; //all exceedances correctly classified
                        fpos[i] = fpos[i] + fold["tneg"][0] + fold["fpos"][0]; //all non-exceedances incorrectly classified
                    }
                }
                
                sens.Add(tpos[i] / (tpos[i] + fneg[i]));
            }

            //Add the summarized result to the output structure:
            Sorted.Add(spec);
            Sorted.Add(sens);
            Sorted.Add(tpos);
            Sorted.Add(tneg);
            Sorted.Add(fpos);
            Sorted.Add(fneg);
        
            return Sorted;
        }
    }
}
