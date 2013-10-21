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
