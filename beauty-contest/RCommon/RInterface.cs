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
            engine = REngine.CreateInstance("RDotNet");
            engine.Initialize();

            // Write the size of the R stack allocation to test whether we've successfuly bumped it up to 10MB
            /*CharacterVector testResult = engine.Evaluate("Cstack_info()").AsCharacter();
            Console.WriteLine(testResult[0].ToString());

            using (StreamWriter w = File.AppendText("c:\\Users\\wrbrooks\\log.txt"))
            {
                w.WriteLine(testResult[0].ToString());
            }*/
        }
    }
}
