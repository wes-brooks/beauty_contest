# R.NET (and IronPython) specific:
import random
from datetime import datetime

import sys
import os
dlls = os.getcwd().split(os.sep)[:-1]
dlls.append("bin")
dlls = os.sep.join(dlls)
sys.path.append(os.sep.join(dlls))

import clr
clr.AddReference("R.NET")
clr.AddReference("RDotNetExtensions")

import RDotNet
import RDotNetExtensions

from System import Array
import array

#Fire up the interface to R
os.environ["R_HOME"] = dlls + os.sep + 'R-2.15.1'
RDotNet.REngine.SetDllDirectory(dlls + os.sep + os.sep.join(['R-2.15.1','bin','i386']))
r = RDotNet.REngine.CreateInstance("RDotNet", output=RDotNet.Internals.OutputMode.Quiet)

#This class wraps the R.NET functionality and makes calling r functions simpler.
class Wrap():
    def __init__(self):
        self.r = r
        random.seed( datetime.now().microsecond ) #we'll use random numbers to name objects in r
        
    def Call(self, function, **params):
        #This function translates function calls into a form that R.NET can understand
        
        #start the command string with the function name:
        command = str(function) + "("
        
        for item in params:
            if isinstance(params[item], str): #put quotes around strings
				params[item] = "'" +  params[item] + "'"
            
            elif isinstance(params[item], bool): #convert boolean types to T or F
                if params[item] is True: params[item] = "TRUE"
                else: params[item] = "FALSE"    
            
            elif isinstance(params[item], (float, int)): #, np.number)): #convert numeric types to strings
                params[item] = str(params[item])

            elif isinstance(params[item], RDotNet.SymbolicExpression):
                #make sure we have a name by which we can refer to R objects
                robj_name = "r_" + str(random.random())[2:]
                r.SetSymbol(robj_name, params[item])
                params[item] = robj_name
                
            elif isinstance(params[item], (array.array, list)):
                try:
                    temp = array.array('d', params[item])
                except OverflowError:
                    temp = params[item]
                
                #move the array into R
                if temp.typecode in ['d', 'f']:
                    temp = r.CreateNumericVector( Array[float](temp) ).AsVector()
                else:
                    temp = r.CreateCharacterVector( Array[str](temp) ).AsVector()
                    
                #make sure we have a name by which we can refer to R objects
                robj_name = "r_" + str(random.random())[2:-4]
                r.SetSymbol(robj_name, temp)
                params[item] = robj_name
                
            #Now piece together the R function call:
            command = command + item + "=" + params[item] + ", "
            
        command = command[:-2] + ")"
        print command
        result = self.r.EagerEvaluate(command)
        
        return result