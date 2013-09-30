using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

using RDotNet;
using RDotNet.NativeLibrary;

namespace RCommon
{
    public static class RInterface
    {
        private static REngine engine;

        public static REngine R
        {
            get { return engine; }
        }

        static RInterface()
        {
            // Set the folder in which R.dll locates.
            // See Documentation for automatic search of installation path.
            var envPath = Environment.GetEnvironmentVariable("PATH");
            var rBinPath = AppDomain.CurrentDomain.BaseDirectory + @"\R-3.0.1\bin\i386";
            rBinPath = @"..\..\..\..\bin\R-3.0.1\bin\i386";
            Environment.SetEnvironmentVariable("PATH", envPath + Path.PathSeparator + rBinPath);
            //Environment.SetEnvironmentVariable("R_HOME", AppDomain.CurrentDomain.BaseDirectory + @"\R-3.0.1");
            Environment.SetEnvironmentVariable("R_HOME",  @"..\..\..\..\bin\R-3.0.1");

            // For Linux or Mac OS, R_HOME environment variable may be needed.
            //Environment.SetEnvironmentVariable("R_HOME", "/usr/lib/R")

            engine = REngine.CreateInstance("RDotNet");
            // From v1.5, REngine requires explicit initialization.
            // You can set some parameters.
            engine.Initialize();

            // Test difference of mean and get the P-value.
            CharacterVector testResult = engine.Evaluate("Cstack_info()").AsCharacter();
            Console.WriteLine(testResult[0].ToString());

            using (StreamWriter w = File.AppendText("c:\\log.txt"))
            {
                w.WriteLine(testResult[0].ToString());
            }
        }
    }
}
