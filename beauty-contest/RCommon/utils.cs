using System;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Collections.Generic;
using System.Text;
using System.Data;

using RDotNet;
using RDotNet.NativeLibrary;

namespace RCommon
{
    public delegate void ModelProgressDelegate(string Message, double Progress);
    public delegate void ModelValidationCompleteDelegate(ValidationAndModel Result);
    public delegate void ModelCancelledDelegate(string Message);

    public class HeadersAndData
    {
        public string[] headers;
        public List<double[]> data;

        public HeadersAndData(string[] Headers, List<double[]> Data)
        {
            headers = Headers;
            data = Data;
        }
    }


    public class ValidationAndModel
    {
        private List<Dictionary<string, List<double>>> validation;
        private RModelInterface model;

        public RModelInterface Model { get { return model; } }
        public List<Dictionary<string, List<double>>> Validation { get { return validation; } }

        public ValidationAndModel(List<Dictionary<string, List<double>>> Validation, RModelInterface Model)
        {
            validation = Validation;
            model = Model;
        }
    }


    public class ProgressArgs
    {
        private string message;
        private double progress;

        public string Message {get {return message;}}
        public double Progress {get {return progress;}}

        public ProgressArgs(string Message, double Progress)
        {
            message = Message;
            progress = Progress;
        }
    }
    
    
    public class ModelValidationResult
    {
        private ValidationAndModel result;
        private Func<double> callback;

        public ValidationAndModel Result { get { return result; } }
        public Func<double> Progress {get {return callback;}}

        public ModelValidationResult(ValidationAndModel Result, Func<double> Callback)
        {
            result = Result;
            callback = Callback;
        }
    }
	
	
    public class ModelCancelledEventArgs : EventArgs
    {
        private string message;
        private Func<double> callback;

        public string Message {get {return message;}}
        public Func<double> Progress {get {return callback;}}

        public ModelCancelledEventArgs(string Message, Func<double> Callback)
        {
            message = Message;
            callback = Callback;
        }
    }


	public static class utils
	{
		public static Random rng = new Random ((int)System.DateTime.Now.Ticks);

        public static DataTable ReadCSV(String filename, Char delimiter = ',', Boolean firstRowHeaders = true)
        {
            StreamReader sr = null;
            DataTable data = null;

            try
            {
                if ((filename == null) || (filename == ""))
                    throw new Exception("File has not been specified.");
                if (!File.Exists(filename))
                    throw new Exception("Could not find file: " + filename);

                data = new DataTable();
                sr = new StreamReader(filename);

                // Read the header and extract the field names.
                string line = "";

                if (firstRowHeaders)
                {
                    line = sr.ReadLine();
                    string[] columnNames = line.Split(delimiter);

                    for (int i = 0; i < columnNames.Length; i++)
                    {
                        data.Columns.Add(columnNames[i].Trim());
                        data.Columns[i].DataType = typeof(Double);
                    }
                }

                data.Columns[0].DataType = typeof(String);
                DataRow dr = null;
                line = sr.ReadLine();
                while (line != null && line.Length > 0)
                {
                    string[] cells = line.Split(delimiter);
                    dr = data.NewRow();
                    for (int i = 0; i < cells.Length; i++)
                    {
                        dr[i] = Convert.ToDouble(cells[i]);
                    }
                    data.Rows.Add(dr);
                    line = sr.ReadLine();
                }
            }
            catch (Exception ex)
            {
                return null;
            }
            finally
            {
                if (sr != null)
                    sr.Close();
            }

            return data;
        }


        public static DataTable ProcessData(DataTable Data, String[] Drop=null, String[] Transform=null)
        {
            for (int i = 0; i < Drop.Count(); i++)
            {
                Data.Columns.Remove(Drop[i]);
            }

            return Data;
        }


		public static string RandomString(int size)
		{
			StringBuilder builder = new StringBuilder();
			char ch;
			for (int i = 0; i < size; i++)
			{
				ch = Convert.ToChar(Convert.ToInt32(Math.Floor(26 * rng.NextDouble() + 65)));                 
				builder.Append(ch);
			}

			return builder.ToString();
		}


        public static string SerializeRObject(SymbolicExpression SerializationTarget)
        {
            //First, get the serialized gbm model object out of R (we have to write it to disk first)
            string robject_file = utils.RandomString(10) + ".robj";
            string scratchdir = System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "VirtualBeach");

            if (scratchdir != "")
            {
                List<string> dirparts = scratchdir.Split(Path.DirectorySeparatorChar).ToList();
                dirparts.Add(robject_file);
                robject_file = String.Join(Path.DirectorySeparatorChar.ToString(), dirparts);
            }
            robject_file = robject_file.Replace("\\", "\\\\");

            //Serialize the R object to disk
            RInterface.R.SetSymbol("obj", SerializationTarget);
            RInterface.R.Evaluate("save(save=obj, ascii=TRUE, file='" + robject_file + "')");

            //Read the serialized object into C# as a bytearray
            StreamReader reader = new StreamReader(File.Open(robject_file, FileMode.Open), System.Text.Encoding.ASCII);
            string modelstring = reader.ReadToEnd();
            reader.Close();
            File.Delete(robject_file);

            return (modelstring);
        }


        public static  SymbolicExpression DeserializeRObject(string SerializedObject)
        {
            //First, get the serialized gbm model object out of R (we have to write it to disk first)
            string robject_file = utils.RandomString(10) + ".robj";
            string scratchdir = System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "VirtualBeach");

            if (scratchdir != "")
            {
                List<string> dirparts = scratchdir.Split(Path.DirectorySeparatorChar).ToList();
                dirparts.Add(robject_file);
                robject_file = String.Join(Path.DirectorySeparatorChar.ToString(), dirparts);
            }
            robject_file = robject_file.Replace("\\", "\\\\");

            //Write the serialized object to disk:
            StreamWriter writer = new StreamWriter(File.Open(robject_file, FileMode.Create), System.Text.Encoding.ASCII);
            writer.Write(SerializedObject); //.ReadBytes((int)reader.BaseStream.Length);
            writer.Close();

            //Read the serialized object into R:
            SymbolicExpression result = RInterface.R.Evaluate("load(file='" + robject_file + "')");
            File.Delete(robject_file);

            return (result);
        }


		public static DataFrame DictionaryToR(Dictionary<string, double[]> Data)
		{
			//#set up variables we'll need later
			Dictionary<string, DynamicVector> df = new Dictionary<string, DynamicVector>();
			//Dictionary<string, DynamicVector> cols = new Dictionary<string, DynamicVector>();
			string command = "data.frame(";

			///#each column of the dictionary should be a numpy array
			foreach (KeyValuePair<string, double[]> col in Data)
			{
				df.Add(col.Key, RInterface.R.CreateNumericVector(col.Value).AsVector());
				
				//#Update the command and give the column a random name in R
				string r_col_name = SanitizeVariableName(col.Key);
				string col_name = "col_" + rng.Next(100000001).ToString();
				command = command + r_col_name + "=" + col_name + ",";
				RInterface.R.SetSymbol(col_name, df[col.Key]);        
			}

			//#create the data frame in R
			command = command.TrimEnd(',') + ")";
			DataFrame data_frame = RInterface.R.Evaluate(command).AsDataFrame();

			//#Destroy the temporary objects:
			//RInterface.R.Evaluate("rm(list=ls(pattern='^col'))");

			//#Return the data frame
			return(data_frame);
		}


		public static HeadersAndData DotNetToArray(DataTable data)
		{
			//Copy the contents of a .NET DataView into a numpy array with a list of headers
            DataView dataview;
            dataview = data.AsDataView();

			/*//Determine whether we got a DataTable or a DataView
			if (data.GetType() == typeof(System.Data.DataTable)) {
                dataview = data.AsDataView();
            }
            else if (data.GetType() == typeof(System.Data.DataView))
            {
                dataview = data;
			}
			else {return("data was passed to Python in an invalid type");}*/

			//Extract the column headers:
            string[] headers = (from DataColumn column in dataview.Table.Columns select column.Caption).ToArray();

			//Find which rows of the DataView contain NaNs:
            int[] nan_rows = (from DataRowView row in dataview select (from item in row.Row.ItemArray select item.GetType()==typeof(System.DBNull) ? 1 : 0).Sum()).ToArray();
			bool[] flags = (from i in Enumerable.Range(0, nan_rows.Length) select nan_rows[i]==0).ToArray();

			//Now copy the NaN-free rows of the DataView into an array:
            List<DataRow> raw_table = (from i in Enumerable.Range(0, dataview.Count) where flags[i] select dataview[i].Row).ToList<DataRow>();
			List<double[]> data_array = (from i in Enumerable.Range(0, dataview.Table.Columns.Count - 1) select (from row in raw_table select row.ItemArray.OfType<double>().ToArray()[i]).ToArray()).ToList();

			return(new HeadersAndData(headers, data_array));
		}



		public static string SanitizeVariableName(string var)
		{
			//#First remove any leading characters that are not letters, then any other characters that are not alphanumeric.
			var = Regex.Replace (var, "^[^a-zA-Z]+", "");
			return(Regex.Replace(var, "[^a-zA-Z0-9]+", ""));
		}


		public static double std(IEnumerable<double> values)
		{   
			double ret = 0;
			if (values.Count() > 0) 
			{      
				//Compute the Average      
				double avg = values.Average();
				//Perform the Sum of (value-avg)_2_2      
				double sum = values.Sum(d => Math.Pow(d - avg, 2));
				//Put it all together      
				ret = Math.Sqrt((sum) / (values.Count()-1));   
			}   
			return ret;
		}


		public static double Median(double[] sourceNumbers) {
			//Framework 2.0 version of this method. there is an easier way in F4        
			if (sourceNumbers == null || sourceNumbers.Length == 0)
				return 0D;

			//make sure the list is sorted, but use a new array
			double[] sortedPNumbers = (double[])sourceNumbers.Clone();
			sourceNumbers.CopyTo(sortedPNumbers, 0);
			Array.Sort(sortedPNumbers);

			//get the median
			int size = sortedPNumbers.Length;
			int mid = size / 2;
			double median = (size % 2 != 0) ? (double)sortedPNumbers[mid] : ((double)sortedPNumbers[mid] + (double)sortedPNumbers[mid - 1]) / 2;
			return median;
		}


		public static double Quantile(double[] values, double q)
		{
			//Find the value at the specified quantile of the list.
			if (q > 1 || q < 0) {
				return(Double.NaN);
			} else {
				List<double> list = values.ToList();
                list.Sort();
				int position = (int)Math.Ceiling(q * (list.Count - 1));
				return(list[position]);
			}
		}


        public static int[] Partition(List<double[]> data, int folds)
        {
            //Partition the data set into random, equal-sized folds for cross-validation
            int[] fold;
            int nobs = data.First().Length;

            //If we've called for leave-one-out CV (folds will be like 'n' or 'LOO' or 'leave-one-out')
            if (folds.ToString().ToLower()[0]=='l' || folds.ToString().ToLower()[0]=='n' || folds>nobs)
            {
                fold = Enumerable.Range(0, nobs).ToArray();
            }
    
            //Otherwise, randomly permute the data, then use contiguously-permuted chunks for CV
            else
            {
                //Initialization
                double[] indices = (from k in Enumerable.Range(0, nobs) select Convert.ToDouble(k)).ToArray();
                fold = (from k in Enumerable.Range(0, nobs) select folds).ToArray();
                double[] quantiles = (from x in Enumerable.Range(0, folds) select (double)x/(double)folds).ToArray();
        
                //Proceed through the quantiles in reverse order, labelling the ith fold at each step. Ignore the zeroth quantile.
                for (int i=folds; i>0; i--)
                {
                    int q = Convert.ToInt32(Quantile(indices, quantiles[i-1]));
                    //int[] qq = (from j in Enumerable.Range(0, q) select i).OfType<int>().ToArray();
                    for (int k=0; k<q; k++) {fold[k] = i-1;}
                }
            
                //Now permute the fold assignments
                fold = fold.OrderBy(x => utils.rng.Next()).ToArray();
            }
        
            return(fold);
        }


        public static Dictionary<string, List<double>> GetPossibleSpecificities(RModelInterface Model)
        {
            //Find out what values specificity could take if we count out one non-exceedance at a time.'''
            double regulatory = Model.Regulatory;
            List<double> fitted = Model.Fitted;
            List<double> actual = Model.Actual;

            List<double> thresholds = (from i in Enumerable.Range(0, fitted.Count) where actual[i] <= regulatory select fitted[i]).ToList();
            thresholds.Sort();

            //The (i+1) here is because we need to count the threshold value as a non-exceedance.
            List<double> specificities = (from i in Enumerable.Range(0, thresholds.Count) select (double)(i+1)/(double)(thresholds.Count)).ToList();
            return (new Dictionary<string, List<double>> { 
                {"thresholds", thresholds},
                {"specificities", specificities} });
        }


        public static Dictionary<string, List<double>> SpecificityChart(ValidationAndModel Result)
        {
            //Produces a list of lists that Virtual Beach turns into a chart of performance in prediction as we sweep the specificity parameter.
            List<double> specificities = new List<double>();
            foreach (Dictionary<string, List<double>> fold in Result.Validation)
            {
                specificities.AddRange(fold["specificity"]);
            }

            specificities = specificities.Distinct().ToList();
            specificities.Sort();
    
            List<double> spec = new List<double>();
            List<double> tpos = new List<double>();
            List<double> tneg = new List<double>();
            List<double> fpos = new List<double>();
            List<double> fneg = new List<double>();
            List<double> thresh = new List<double>();
    
            foreach (double specificity in specificities)
            {
                tpos.Add(0);
                tneg.Add(0);
                fpos.Add(0);
                fneg.Add(0);
                spec.Add(specificity);
                thresh.Add(Result.Model.GetThreshold(specificity)[0]);
                int j = tpos.Count - 1;

                foreach (Dictionary<string, List<double>> fold in Result.Validation)
                {
                    int nobs = fold["specificity"].Count;
                    int[] indx = (from i in Enumerable.Range(0, nobs) where fold["specificity"][i] <= specificity select i).ToArray();
                    if (indx.Length > 0)
                    {
                        int k = (from i in indx where fold["specificity"][i] == (from m in indx select fold["specificity"][m]).ToList().Max() select i).ToArray()[0];
            
                        tpos[j] += fold["tpos"][k];
                        fpos[j] += fold["fpos"][k];
                        tneg[j] += fold["tneg"][k];
                        fneg[j] += fold["fneg"][k];
                    }
                    else
                    {
                        tpos[j] = tpos[j] + fold["tpos"][0] + fold["fneg"][0]; //all exceedances correctly classified
                        fpos[j] = fpos[j] + fold["tneg"][0] + fold["fpos"][0]; //all non-exceedances incorrectly classified
                    }
                }                
            }

            return (new Dictionary<string, List<double>> {
                {"spec", spec},
                {"thresh", thresh},
                {"tpos", tpos},
                {"tneg", tneg},
                {"fpos", fpos},
                {"fneg", fneg} });
        }
	}
}
