import Interface
import clr
import os
clr.AddReference("VBTools")
import VBTools
import utils
import numpy as np
import datetime

et = {}
beaches = {}

beaches['edgewater'] = {'file':'../data/edgewater.xls', 'target':'LogEC', 'transforms':et, 'remove':['id', 'year', 'month'], 'threshold':2.3711}
methods = {"PLS":{}, "gbm":{'depth':2, 'weights':'float'}, "gam":{'k':50}}
cv_folds = 5
B = 1
result = "placeholder"
output = "../output/"

#Set the timestamp we'll use to identify the output files.
now = datetime.datetime.now()
now = [str(now.year), str(now.month), str(now.day), str(now.hour), str(now.minute), str(now.second)]
now = ".".join(now)

for beach in beaches.keys():
    #Read the beach's data.
    datafile = beaches[beach]["file"]
    datafile = VBTools.IO.ExcelOleDb(datafile, firstRowHeaders=True)
    data = datafile.Read(datafile.GetWorksheetNames()[0])
    [headers, data] = utils.DotnetToArray(data)

    #Remove the id column if it is present.
    if beaches[beach]['remove']:
        for col in beaches[beach]['remove']:
            indx = headers.index(col)
            data = np.delete(data, indx, 1)
            headers.remove(col)
    
    for b in range(B):
        #Parition the data into cross-validation folds
        folds = utils.Partition(data, cv_folds)
    
        for f in range(cv_folds+1)[1:]:
            #Break this fold into test and training sets
            training_set = data[np.where(folds==f),:].squeeze()
            inner_cv = utils.Partition(training_set, cv_folds)
            
            #Prepare the test set for use in prediction
            test_set = data[np.where(folds!=f),:]
            test_dict = dict(zip(headers, np.transpose(test_set)))
            
            #Run the modeling routines.
            for method in methods.keys():
                #Run this modeling method against the beach data.
                result = Interface.Interface.Validate(training_set, beaches[beach]['target'], method=method, folds=inner_cv,
                                                        regulatory_threshold=beaches[beach]['threshold'], headers=headers, **methods[method])
                model = result[1]
                results = result[0]
                
                #Store the thresholding information.
                #Open a file to which we will append the output.
                out = open(output + beach + now + method + '_raw_models.out', 'a')
                out.write("#" + method + "\n")
                print >> out, result
                
                #Close the output file and move on.
                out.close()
                
                #Set the threshold for predicting the reserved test set
                indx = np.where(results[0]['tpos'] >= results[0]['fpos'])
                if indx[0].shape[0] > 0:
                    specificity = np.min(results[0]['specificity'][indx])
                else:
                    indx = np.where(results[0]['tpos'] >= results[0]['fneg'])
                    if indx[0].shape[0] > 0:
                        specificity = np.max(results[0]['specificity'][indx])
                
                #Predict exceedances on the test set and add them to the results structure.
                model.Threshold(specificity)
                predictions = model.Predict(test_dict)
                
                #Store the performance information.
                #Open a file to which we will append the output.
                out = open(output + beach + now + method + '_performance.out', 'a')
                out.write("# fold = " + str(f) + "\n")
                out.write("# threshold = " + str(model.threshold) + "\n")
                out.write("# raw predictions:\n")
                print >> out, predictions
                
                #Close the output file and move on.
                out.close()
            
            
        