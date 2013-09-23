# R.NET (and IronPython) specific:
import random
from datetime import datetime

import sys
import os
dlls = os.getcwd().split(os.sep)[:-1]
dlls.append("bin")
dlls = os.sep.join(dlls)
sys.path.append(dlls)

import clr
clr.AddReference("RDotNet")
clr.AddReference("RDotNet.NativeLibrary")
clr.AddReference("RDotNetExtensions-1.5.0")

#Trick to import package with invalid characters in name:
RDotNet_NativeLibrary = __import__('RDotNet.NativeLibrary')
import RDotNet

from System import Array
import array

#Fire up the interface to R
os.environ["R_HOME"] = dlls + os.sep + 'R-2.15.1'
os.environ["PATH"] += os.pathsep + os.sep.join([dlls,'R-2.15.1','bin','i386'])
r = RDotNet.REngine.CreateInstance("RDotNet")
r.Initialize()

#This class wraps the R.NET functionality and makes calling r functions simpler.
class Wrap():
    def __init__(self):
        self.r = r
        random.seed( datetime.now().microsecond ) #we'll use random numbers to name objects in r
        
    def Call(self, function, *args, **kwargs):
        #This function translates function calls into a form that R.NET can understand        
        #start the command string with the function name:
        command = str(function) + "("
        
        for item in args:
            if isinstance(item, str): #put quotes around strings
                command = command + "'" + item + "', "
        
        for item in kwargs:
            if isinstance(kwargs[item], str): #put quotes around strings
				kwargs[item] = "'" +  kwargs[item] + "'"
            
            elif isinstance(kwargs[item], bool): #convert boolean types to T or F
                if kwargs[item] is True: kwargs[item] = "TRUE"
                else: kwargs[item] = "FALSE"    
            
            elif isinstance(kwargs[item], (float, int)): #, np.number)): #convert numeric types to strings
                kwargs[item] = str(kwargs[item])

            elif isinstance(kwargs[item], RDotNet.SymbolicExpression):
                #make sure we have a name by which we can refer to R objects
                robj_name = "r_" + str(random.random())[2:]
                r.SetSymbol(robj_name, kwargs[item])
                kwargs[item] = robj_name
                
            elif isinstance(kwargs[item], (array.array, list)):
                try:
                    temp = array.array('d', kwargs[item])
                except OverflowError:
                    temp = kwargs[item]
                
                #move the array into R
                if temp.typecode in ['d', 'f']:
                    temp = r.CreateNumericVector( Array[float](temp) ).AsVector()
                else:
                    temp = r.CreateCharacterVector( Array[str](temp) ).AsVector()
                    
                #make sure we have a name by which we can refer to R objects
                robj_name = "r_" + str(random.random())[2:-4]
                r.SetSymbol(robj_name, temp)
                kwargs[item] = robj_name
                
            #Now piece together the R function call:
            command = command + item + "=" + kwargs[item] + ", "
            
        command = command[:-2] + ")"
        #print command
        result = self.r.Evaluate(command)
        
        return result
    
    def Remove(self, obj):
        if isinstance(obj, str): #put quotes around strings
            command = "rm(" + "'" + obj + "')"
        
        print command
        self.r.Evaluate(command)

    def GarbageCollection(self):
        self.r.Evaluate("gc()")    