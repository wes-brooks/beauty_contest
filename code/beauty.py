import Interface
import clr
import os
clr.AddReference("VBTools")
import VBTools
import utils
import numpy as np
import datetime

class ValidationCounts(object):
    def __init__(self):
        self.tpos = 0
        self.tneg = 0
        self.fpos = 0
        self.fneg = 0
        self.predictions = np.array([])
        self.truth = np.array([])
    
    
beaches = {}

#beaches['edgewater'] = {'file':'../data/edgewater.xls', 'target':'LogEC', 'transforms':{}, 'remove':['id', 'year', 'month'], 'threshold':2.3711}
#beaches['redarrow'] = {'file':'../data/RedArrow2010-11_for_workshop.xls', 'target':'EColiValue', 'transforms':{'EColiValue':np.log10}, 'remove':['pdate'], 'threshold':2.3711}
beaches['redarrow'] = {'file':'../data/RA-VB1.xlsx', 'target':'logEC', 'remove':['beachEColiValue', 'CDTTime', 'beachTurbidityBeach', 'tribManitowocRiverTribTurbidity'], 'threshold':2.3711, 'transforms':[]}
methods = {"lasso":{'left':0, 'right':3.383743576}} #{"PLS":{}, "gbm":{'depth':5, 'weights':'float', 'minobsinnode':5, 'iterations':10000, 'shrinkage':0.001}}#, "gam":{'k':50, 'julian':'jday'}}
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
    datafile.CloseConnection()
    if 'remove' in beaches[beach]: [headers, data] = utils.DotnetToArray(data, remove=beaches[beach]['remove'])
    else: [headers, data] = utils.DotnetToArray(data)
    
    #Apply the specified transforms to the raw data.
    for t in beaches[beach]['transforms']:
        data[:,headers.index(t)] = beaches[beach]['transforms'][t](data[:,headers.index(t)])

    #Remove any columns we've specified.
    #if beaches[beach]['remove']:
    #    for col in beaches[beach]['remove']:
    #        indx = headers.index(col)
    #        data = np.delete(data, indx, 1)
    #        headers.remove(col)
    
    for b in range(B):
        #Partition the data into cross-validation folds.
        folds = utils.Partition(data, cv_folds)
        validation = dict(zip(methods.keys(), [ValidationCounts() for method in methods]))
        
        for f in range(cv_folds+1)[1:]:
            #Break this fold into test and training sets.
            training_set = data[np.where(folds!=f),:].squeeze()
            inner_cv = utils.Partition(training_set, cv_folds)
            
            #Prepare the test set for use in prediction.
            test_set = data[np.where(folds==f),:].squeeze()
            test_dict = dict(zip(headers, np.transpose(test_set)))
            
            #Run the modeling routines.
            for method in methods.keys():
                #Run this modeling method against the beach data.
                result = Interface.Interface.Validate(training_set, beaches[beach]['target'], method=method, folds=inner_cv,
                                                        regulatory_threshold=beaches[beach]['threshold'], headers=headers, **methods[method])
                model = result[1]
                results = result[0]
                thresholding = dict(zip(['specificity', 'tpos', 'tneg', 'fpos', 'fneg'], Interface.Control.SpecificityChart(results)))
                
                #Store the thresholding information.
                #Open a file to which we will append the output.
                out = open(output + beach + now + method + '_raw_models.out', 'a')
                out.write("#" + method + "\n")
                print >> out, result
                
                #Close the output file and move on.
                out.close()
                
                #Set the threshold for predicting the reserved test set
                indx = [i for i in range(len(thresholding['fneg'])) if thresholding['fneg'][i] >= thresholding['fpos'][i] and thresholding['specificity'][i] > 0.8]
                #indx = np.where(results[0]['fneg'] >= results[0]['fpos'] and results[0]['specificity'] > 0.8)
                specificity = np.min(np.array(thresholding['specificity'])[indx])
                
                #Predict exceedances on the test set and add them to the results structure.
                model.Threshold(specificity)
                predictions = np.array(model.Predict(test_dict)).squeeze()
                truth = np.array(test_dict[beaches[beach]['target']]).squeeze()
                
                #Calculate the predictive perfomance for the model
                tpos = sum((predictions>=model.threshold) & (truth>=beaches[beach]['threshold']))
                tneg = sum((predictions<model.threshold) & (truth<beaches[beach]['threshold']))
                fpos = sum((predictions>=model.threshold) & (truth<beaches[beach]['threshold']))
                fneg = sum((predictions<model.threshold) & (truth>=beaches[beach]['threshold']))
                
                #Add predictive performance stats to the aggregate.
                validation[method].tpos = validation[method].tpos + tpos
                validation[method].tneg = validation[method].tneg + tneg
                validation[method].fpos = validation[method].fpos + fpos
                validation[method].fneg = validation[method].fneg + fneg
            
                #Store the performance information.
                #Open a file to which we will append the output.
                out = open(output + beach + now + method + '_performance.out', 'a')
                out.write("# fold = " + str(f) + "\n")
                out.write("# threshold = " + str(model.threshold) + "\n")
                out.write("# requested specificity = " + str(specificity) + "\n")
                out.write("# actual training-set specificity = " + str(model.specificity) + "\n")
                out.write("# tpos = " + str(tpos) + "\n")
                out.write("# tneg = " + str(tneg) + "\n")
                out.write("# fpos = " + str(fpos) + "\n")
                out.write("# fneg = " + str(fneg) + "\n")
                out.write("# raw predictions:\n")
                print >> out, predictions
                out.write("# truth:\n")
                print >> out, truth
                
                #Close the output file and move on.
                out.close()
            
        for m in methods.keys():
            #Store the performance information.
            #Open a file to which we will append the output.
            out = open(output + beach + now + m + '_performance.out', 'a')
            out.write("# fold = overall performance\n")
            out.write("# tpos = " + str(validation[m].tpos) + "\n")
            out.write("# tneg = " + str(validation[m].tneg) + "\n")
            out.write("# fpos = " + str(validation[m].fpos) + "\n")
            out.write("# fneg = " + str(validation[m].fneg) + "\n")
            
            #Close the output file and move on.
            out.close()
            
            
        