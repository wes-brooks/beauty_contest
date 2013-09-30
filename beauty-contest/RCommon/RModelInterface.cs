using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;

using RDotNet;
using RDotNet.NativeLibrary;

namespace RCommon
{
    public interface RModelInterface
    {
        List<double> Actual {get;}
        List<double> Fitted {get;}
        List<double> Residuals {get;}
        double Threshold {get;}
        double Regulatory {get;}
        double Specificity {get;}
        SymbolicExpression RModelObject { get; }

        void SetThreshold(double Specificity);
        double[] GetThreshold(double Specificity);
        string GetModelExpression();
        List<double> Predict(DataTable Data);
        List<double> PredictExceedanceProbability(DataTable Data, double Threshold);
    }
}
