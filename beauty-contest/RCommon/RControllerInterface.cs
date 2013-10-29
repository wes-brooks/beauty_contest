using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;

namespace RCommon
{
    public interface RControllerInterface
    {
        void Validate(DataTable Data, string Target, double Threshold, double Specificity, int Folds, ModelValidationCompleteDelegate CompletionCallback);
    }
}
