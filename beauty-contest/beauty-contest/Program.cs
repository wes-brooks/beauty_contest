using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using RCommon;
using RDotNet;
using RDotNet.NativeLibrary;

namespace beauty_contest
{
    class Program
    {
        static void Main(string[] args)
        {
            GBM.GBMController c1 = new GBM.GBMController();
            RCommon.RInterface.R.Evaluate("2+2");
        }
    }
}
