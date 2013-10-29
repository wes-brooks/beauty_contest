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
        public void Start(string[] args)
        {
            if (args.Count() > 1)
            {
                String line;
                using (StreamReader sr = new StreamReader("../seeds.txt"))
                {
                    line = sr.ReadToEnd();
                }
    
                int cluster = Convert.ToInt32(args[1]);
                int process = Convert.ToInt32(args[2]);

                int seed = 1000 * float(seeds[s*mm[0]+d[1]].strip())
    
                print "locs: " + str(locs)
                print "tasks: " + str(tasks);
            }
            else
            {
                string prefix = "NA";
                string beach = "NA";
                string method = "NA";
            }

        }


        public void Analyze(HeadersAndData Dataset, int nfolds)
        { 
            List<double[]> data = Dataset.data;
            string[] headers = Dataset.headers;
            int nrows = data[0].Count();
            int ncols = data.Count();

            //Partition the data into cross-validation folds.
            int[] folds = utils.Partition(data, nfolds);

            validation = dict(zip(methods.keys(), [ValidationCounts() for method in methods]))
        
            Dictionary<string, List<double>> ROC = new Dictionary<string, List<double>>()
            {
                {"train", new List<double>()},
                {"fitted", new List<double>()},
                {"validate", new List<double>()},
                {"predicted", new List<double>()},
                {"threshold", new List<double>()}
            };

            for (int f=1; f<=nfolds; f++)
            {
                Console.Write("outer fold: " + f.ToString() + "\n");

                //Break this fold into test and training sets.
                List<double[]> training_set = new List<double[]>();
                for (int k=0; k<ncols; k++)
                {
                    training_set.Add((from i in Enumerable.Range(0, nrows) where folds[i]!=f select data[k][i]).ToArray<double>());
                }                
            
                //Prepare the test set for use in prediction.
                List<double[]> test_set = new List<double[]>();
                for (int k=0; k<ncols; k++)
                {
                    test_set.Add((from i in Enumerable.Range(0, nrows) where folds[i]==f select data[k][i]).ToArray<double>());
                }

                Dictionary<string, double[]> test_dict = headers.Zip(test_set, (header, values) => new { header, values })
                          .ToDictionary(item => item.header, item => item.values);
                //dict(zip(headers, [array.array('d', [row[i] for row in test_set]) for i in range(len(test_set[0]))]))
            
                int[] inner_folds = utils.Partition(training_set, nfolds);

                //Run the modeling routine.
                if (f==1)
                {
                    using (System.IO.StreamWriter file = new System.IO.StreamWriter("../output/" + String.Join(".", new string[] {prefix, beach, method, "out"})))
                    {
                        if (seed) {file.Write("# Seed = " + seed.ToString() + "\n");}
                        file.Write("# Site = " + beach + "\n");
                        file.Write("# Method = " + method + "\n");                        
                    }
                }
            
                //Run this modeling method against the beach data.
                result = Interface.Interface.Validate(training_set, beaches[beach]['target'], method=method, folds=inner_cv,
                                                        regulatory_threshold=beaches[beach]['threshold'], headers=headers, **methods[method])
                model = result[1]
                results = result[0]
                thresholding = dict(zip(['specificity', 'sensitivity', 'tpos', 'tneg', 'fpos', 'fneg'], Interface.Control.SpecificityChart(results)))
                
                //Store the thresholding information.
                //Open a file to which we will append the output.
                //out = open(output + beach + now + method + '_raw_models.out', 'a')
                //out.write("#" + method + "\n")                
                //print >> out, result
                
                //Close the output file and move on.
                //out.close()
                
                //Set the threshold for predicting the reserved test set
                //indx = [i for i in range(len(thresholding['fneg'])) if thresholding['fneg'][i] >= thresholding['fpos'][i] and thresholding['specificity'][i] > 0.8]
                //if not indx:
                //    indx = [i for i in range(len(thresholding['fneg'])) if thresholding['specificity'][i] > 0.8]
                indx = [int(i) for i in range(len(thresholding['fneg'])) if thresholding['fneg'][i] >= thresholding['fpos'][i]]
                if not indx: specificity = 0.9
                else: specificity = min([thresholding['specificity'][i] for i in indx])
                
                //Predict exceedances on the test set and add them to the results structure.
                model.Threshold(specificity)
                predictions = model.Predict(test_dict)
                truth = test_dict[beaches[beach]['target']]
                
                //These will be used to calculate the area under the ROC curve:
                order = sorted(range(len(truth)), key=truth.__getitem__)
                ROC["validate"].Add(truth);
                ROC["predicted"].Add(predictions);
                ROC["train"].Add(model.actual);
                ROC["fitted"].Add(model.fitted);
                
                //Calculate the predictive perfomance for the model
                tpos = len([i for i in range(len(predictions)) if predictions[i] > model.threshold and truth[i] > beaches[beach]['threshold']])
                tneg = len([i for i in range(len(predictions)) if predictions[i] <= model.threshold and truth[i] <= beaches[beach]['threshold']])
                fpos = len([i for i in range(len(predictions)) if predictions[i] > model.threshold and truth[i] <= beaches[beach]['threshold']])
                fneg = len([i for i in range(len(predictions)) if predictions[i] <= model.threshold and truth[i] > beaches[beach]['threshold']])
                
                //Add predictive performance stats to the aggregate.
                validation[method].tpos = validation[method].tpos + tpos
                validation[method].tneg = validation[method].tneg + tneg
                validation[method].fpos = validation[method].fpos + fpos
                validation[method].fneg = validation[method].fneg + fneg
            
                //Store the performance information.
                //Open a file to which we will append the output.
                out = open(output + ".".join([prefix, beach, method, "out"]), 'a')
                out.write("# fold = " + str(f) + "\n")
                out.write("# threshold = " + str(model.threshold) + "\n")
                out.write("# requested specificity = " + str(specificity) + "\n")
                out.write("# actual training-set specificity = " + str(model.specificity) + "\n")
                out.write("# tpos = " + str(tpos) + "\n")
                out.write("# tneg = " + str(tneg) + "\n")
                out.write("# fpos = " + str(fpos) + "\n")
                out.write("# fneg = " + str(fneg) + "\n")                
                out.write("# raw predictions:\n")
                print >> out, predictions
                out.write("# truth:\n")
                print >> out, truth
                out.write("# fitted:\n")
                print >> out, model.fitted
                out.write("# actual:\n")
                print >> out, model.actual
                
                //Clean up and move on.
                out.close()
                objlist = list(r.Call('ls()').AsVector())
                print "in main loop of beauty.py"
                print objlist
                for obj in objlist: r.Remove(obj)
                r.GarbageCollection()
            }
            
            for m in tasks:
                //Store the performance information.
                //First, create a model for variable selection:
                data_dict = dict(zip(headers, [array.array('d', [row[i] for row in data]) for i in range(len(data[0]))]))
                model = Interface.Control.methods[m.lower()].Model(data=data_dict, target=beaches[beach]['target'], regulatory_threshold=beaches[beach]['threshold'], **methods[m])
            
                //Open a file to which we will append the output.
                out = open(output + ".".join([prefix, beach, m, "out"]), 'a')            
                out.write("# Area under ROC curve = " + str(AreaUnderROC(ROC[m])) + "\n")
                out.write("# aggregate.tpos = " + str(validation[m].tpos) + "\n")
                out.write("# aggregate.tneg = " + str(validation[m].tneg) + "\n")
                out.write("# aggregate.fpos = " + str(validation[m].fpos) + "\n")
                out.write("# aggregate.fneg = " + str(validation[m].fneg) + "\n")
                out.write("# variables: " + ", ".join(model.vars) + "\n")
                //out.write("# coefs: " + ", ".join([str(c) for c in model.coefs]) + "\n")
                out.write("# decision threshold: " + str(model.threshold) + "\n")
            
                //Clean up and move on.
                out.close()
                objlist = list(r.Call('ls()').AsVector())
                print "in final loop of beauty.py"
                print objlist          
                for obj in objlist: r.Remove(obj)
                r.GarbageCollection()
                //OutputROC(ROC[method])
        }



        static void Main(string[] args)
        {
            String datapath = "", beach = "", module = "", response = "";
            String[] drop=null;

            //Read the configuration settings:
            String path = Assembly.GetExecutingAssembly().Location;
            String config = path + ".config";
            System.Configuration.AppSettingsReader settings = new System.Configuration.AppSettingsReader();

            if (System.IO.File.Exists(config))
            {
                try
                {
                    //Configuration settings include R's location
                    String rpath = (String)settings.GetValue("RPATH", "String".GetType());
                    String rhome = (String)settings.GetValue("RHOME", "String".GetType());

                    //Set the PATH and R_HOME environment variables based on the configuration settings
                    var envPath = Environment.GetEnvironmentVariable("PATH");
                    Environment.SetEnvironmentVariable("PATH", envPath + Path.PathSeparator + rpath);
                    Environment.SetEnvironmentVariable("R_HOME", rhome);

                    //Load the specifics for this model run from the configuration settings
                    datapath = (String)settings.GetValue("BEACH_DIR", "String".GetType());
                    beach = (String)settings.GetValue("BEACH", "String".GetType());
                    module = (String)settings.GetValue("MODULE", "String".GetType());
                    response = (String)settings.GetValue("RESPONSE", "String".GetType());
                    drop = ((String)settings.GetValue("DROP", "String".GetType())).Split(new Char[] { ',', ' ' },
                                 StringSplitOptions.RemoveEmptyEntries);
                }
                catch { }
            }
 
            //Create a dictionary of modules:
            Dictionary<string, Type> modules = new Dictionary<string, Type>();
            modules.Add("PLS", typeof(PLS.PLSController));
            modules.Add("GBM", typeof(GBM.GBMController));

            //Load the appropriate one based on the configuration file
            Type mod = modules[module];

            //Read the datafile that was specified in the configuration file:
            DataTable data = utils.ReadCSV(Path.Combine(datapath, beach));
            data = utils.ProcessData(Data: data, Drop: drop);

            //Create an instance of the model validator:
            RControllerInterface model_interface = (RControllerInterface)(Activator.CreateInstance(mod));

            model_interface.Validate(Data: data, Target: response, Threshold: 2.3711, Specificity: 0.9, Folds: 5, CompletionCallback: Summarize);
        }
    }
}
