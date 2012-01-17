import Interface
import clr
import os
clr.AddReference("VBTools")
import VBTools
import utils
import numpy as np
import datetime

et = {}
control = {}
control['edgewater'] = {'file':'../data/edgewater.xls', 'target':'LogEC', 'transforms':et, 'remove':['id', 'year'], 'threshold':2.3711}
methods = ["PLS"]
cv_folds = 5
B = 3
result = "placeholder"
output = "../output/"

#Set the timestamp we'll use to identify the output files.
now = datetime.datetime.now()
now = [str(now.year), str(now.month), str(now.day), str(now.hour), str(now.minute), str(now.second)]
now = ".".join(now)

for beach in control.keys():
    #Read the beach's data.
    datafile = control[beach]["file"]
    datafile = VBTools.IO.ExcelOleDb(datafile, firstRowHeaders=True)
    data = datafile.Read(datafile.GetWorksheetNames()[0])
    [headers, data] = utils.DotnetToArray(data)

    #Remove the id column if it is present.
    if control[beach]['remove']:
        for col in control[beach]['remove']:
            indx = headers.index(col)
            data = np.delete(data, indx, 1)
            headers.remove(col)
    
    for b in range(B):
        #Parition the data into cross-validation folds
        folds = utils.Partition(data, cv_folds)
    
        #Run the modeling routines.
        for method in methods:
            #Run this modeling method against the beach data.
            result = Interface.Interface.Validate(data, control[beach]['target'], method=method, folds=folds,
                                                    regulatory_threshold=control[beach]['threshold'], headers=headers)
            
            #Store the results.
            #Open a file to which we will append the output.
            out = open(output + beach + now + '.out', 'a')
            out.write("#" + method + "\n")
            print >> out, result
            
            #Close the output file and move on.
            out.close()
            
        