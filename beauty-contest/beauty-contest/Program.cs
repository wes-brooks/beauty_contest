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
