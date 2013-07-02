import Interface
import clr
import os
import sys
clr.AddReference("VBTools")
import VBTools
import utils
#import numpy as np
import datetime
import copy
import random
import array

class ValidationCounts(object):
    def __init__(self):
        self.tpos = 0
        self.tneg = 0
        self.fpos = 0
        self.fneg = 0
        self.predictions = list()
        self.truth = list()
    
    
beaches = dict()
##beaches['edgewater'] = {'file':'../data/edgewater.xls', 'target':'LogEC', 'transforms':{}, 'remove':['id', 'year', 'month'], 'threshold':2.3711}
##beaches['redarrow'] = {'file':'../data/RedArrow2010-11_for_workshop.xls', 'target':'EColiValue', 'transforms':{'EColiValue':np.log10}, 'remove':['pdate'], 'threshold':2.3711}
##beaches['redarrow'] = {'file':'../data/RA-VB1.xlsx', 'target':'logEC', 'remove':['beachEColiValue', 'CDTTime', 'beachTurbidityBeach', 'tribManitowocRiverTribTurbidity'], 'threshold':2.3711, 'transforms':[]}
#beaches['hika'] = {'file':'../data/Hika.csv', 'target':'observation', 'remove':['beachEColiValue', 'time'], 'threshold':2.3711, 'transforms':[]}
#beaches['fisher'] = {'file':'../data/Fisher.csv', 'target':'observation', 'remove':['beachEColiValue', 'datetime'], 'threshold':2.3711, 'transforms':[]}
#beaches['kreher'] = {'file':'../data/Kreher.csv', 'target':'logecoli', 'remove':['beachEColiValue', 'dates'], 'threshold':2.3711, 'transforms':[]}
#beaches['maslowski'] = {'file':'../data/Maslowski.csv', 'target':'logecoli', 'remove':['beachEColiValue', 'dates'], 'threshold':2.3711, 'transforms':[]}
#beaches['neshotah'] = {'file':'../data/Neshotah.csv', 'target':'logec', 'remove':['beachEColiValue', 'dates'], 'threshold':2.3711, 'transforms':[]}
#beaches['pointconcessions'] = {'file':'../data/PointConcessions.csv', 'target':'logec', 'remove':['beachEColiValue', 'dates'], 'threshold':2.3711, 'transforms':[]}
beaches['pointlakeshore'] = {'file':'../data/PointLakeshore.csv', 'target':'logec', 'remove':['beachEColiValue', 'dates'], 'threshold':2.3711, 'transforms':[]}
#beaches['pointlighthouse'] = {'file':'../data/PointLighthouse.csv', 'target':'logec', 'remove':['beachEColiValue', 'dates'], 'threshold':2.3711, 'transforms':[]}
#beaches['redarrow'] = {'file':'../data/RedArrow.csv', 'target':'logecoli', 'remove':['beachEColiValue', 'CDTTime'], 'threshold':2.3711, 'transforms':[]}
#beaches['thompson'] = {'file':'../data/Thompson.csv', 'target':'observation', 'remove':['beachEColiValue', 'dates'], 'threshold':2.3711, 'transforms':[]}
##beaches['huntington'] = {'file':'../data/HuntingtonBeach.csv', 'target':'logecoli', 'remove':[], 'threshold':2.3711, 'transforms':[]}

methods = dict()
##methods["lasso"] = {'left':0, 'right':3.383743576, 'adapt':True, 'overshrink':True, 'precondition':False}
#methods["PLS"] = {}
#methods["gbm-weighted"] = {'depth':5, 'weights':'discrete', 'minobsinnode':5, 'iterations':20000, 'shrinkage':0.0001, 'gbm.folds':0}
#methods["gbmcv-weighted"] = {'depth':5, 'weights':'discrete', 'minobsinnode':5, 'iterations':20000, 'shrinkage':0.0001, 'gbm.folds':5}
#methods["gbm-unweighted"] = {'depth':5, 'weights':'none', 'minobsinnode':5, 'iterations':20000, 'shrinkage':0.0001, 'gbm.folds':0}
#methods["gbmcv-unweighted"] = {'depth':5, 'weights':'none', 'minobsinnode':5, 'iterations':20000, 'shrinkage':0.0001, 'gbm.folds':5}
##methods["gam"] = {'k':50, 'julian':'jday'}
##methods['logistic'] = {'weights':'discrete', 'stepdirection':'both'}
#methods['galogistic-weighted'] = {'weights':'discrete', 'generations':100, 'mutate':0.05}
#methods['adalasso-weighted'] = {'weights':'discrete', 'adapt':True, 'overshrink':True, 'precondition':False}
##methods['adalasso-weighted-preconditioned'] = {'weights':'discrete', 'adapt':True, 'overshrink':True, 'precondition':True}
#methods['galogistic-unweighted'] = {'weights':'none', 'generations':100, 'mutate':0.05}
#methods['adalasso-unweighted'] = {'weights':'none', 'adapt':True, 'overshrink':True, 'precondition':False}
methods['adalasso-unweighted-select'] = {'weights':'none', 'adapt':True, 'overshrink':True, 'precondition':False, 'selectvars':True}
methods['adalasso-weighted-select'] = {'weights':'discrete', 'adapt':True, 'overshrink':True, 'precondition':False, 'selectvars':True}
##methods['adalasso-unweighted-preconditioned'] = {'weights':'none', 'adapt':False, 'overshrink':True, 'precondition':True}
#methods["galm"] = {'generations':100, 'mutate':0.05}
#methods["adapt"] = {'adapt':True, 'overshrink':True, 'precondition':False, 'selectvars':False}
#methods["adapt-select"] = {'adapt':True, 'overshrink':True, 'precondition':False, 'selectvars':True}
#methods["spls"] = {'selectvars':False}
#methods["spls-select"] = {'selectvars':True}
##methods["precondition"] = {'adapt':False, 'overshrink':True, 'precondition':True}


#We call this script with command line arguments from Condor
if len(sys.argv) > 1:
    f = open("../seeds.txt", 'r')
    seeds = f.readlines()
    f.close()
    
    cluster = int(sys.argv[1])
    process = int(sys.argv[2])
    sites = beaches.keys()
    
    s = len(sites)
    m = len(methods.keys())
    d = divmod(process, s)
    mm = divmod(d[0], m)
    
    print "s: " + str(s)
    print "m: " + str(m)
    print "d: " + str(d)
    print "mm: " + str(mm)
    
    locs = [sites[d[1]]]    
    tasks = [methods.keys()[mm[1]]]
    seed = 1000 * float(seeds[s*mm[0]+d[1]].strip())
    
    print "locs: " + str(locs)
    print "tasks: " + str(tasks)
    print "seed: " + str(seed)
    
    #np.random.seed(seed)
else: 
    cluster = "na"
    process = "na"
    locs = beaches.keys()
    tasks = methods.keys()
    seed = ''
    
    
cv_folds = 5
B = 1
result = "placeholder"
output = "../output/"
#output = "../"

#Set the timestamp we'll use to identify the output files.
prefix = [str(cluster), str(process)]
prefix = ".".join(prefix)


def AreaUnderROC(raw):
    threshold = raw['threshold']
    numfolds = len(raw['train'])
    tp = []
    tn = []
    fp = []
    fn = []
    sp = []
    
    for fold in range(numfolds):
        tpos = []
        tneg = []
        fpos = []
        fneg = []
        spec = []
        lenfold = len(raw['train'][fold])
        lenpred = len(raw['validate'][fold])
        
        training_exc = [raw['train'][fold][i] > threshold for i in range(lenfold)] #np.array(raw['train'][fold] > threshold, dtype=bool)
        training_nonexc = [raw['train'][fold][i] <= threshold for i in range(lenfold)] #np.array(raw['train'][fold] <= threshold, dtype=bool)
        thresholds = [raw['fitted'][fold][i] for i in range(lenfold) if training_nonexc[i] == True]
        order = sorted(range(len(thresholds)), key=thresholds.__getitem__) #np.argsort(thresholds)
        
        for i in range(len(order)):
            k = order[i]
            
            spec.append(len([i for i in range(len(thresholds)) if thresholds[i] <= thresholds[k]]) / float(len(thresholds)))
            tpos.append(len([i for i in range(lenpred) if raw['validate'][fold][i] > threshold and raw['predicted'][fold][i] > thresholds[k]]))
            tneg.append(len([i for i in range(lenpred) if raw['validate'][fold][i] <= threshold and raw['predicted'][fold][i] <= thresholds[k]]))
            fpos.append(len([i for i in range(lenpred) if raw['validate'][fold][i] <= threshold and raw['predicted'][fold][i] > thresholds[k]]))
            fneg.append(len([i for i in range(lenpred) if raw['validate'][fold][i] > threshold and raw['predicted'][fold][i] <= thresholds[k]]))
        
        tp.append(tpos)
        tn.append(tneg)
        fp.append(fpos)
        fn.append(fneg)
        sp.append(spec)
    
    specs = []
    [specs.extend(s) for s in sp]
    specs = list(set(specs)) #np.sort(np.unique(specs))
    specs.sort()
    
    tpos = []
    tneg = []
    fpos = []
    fneg = []
    spec = []
    
    folds = len(tp)
    
    for s in specs:
        tpos.append(0)
        tneg.append(0)
        fpos.append(0)
        fneg.append(0)
        spec.append(s)
        
        for f in range(folds):
            indx = [i for i in range(len(sp[f])) if sp[f][i] >= s]
            indx = sorted(indx, key=sp[f].__getitem__)[0]
            
            tpos[-1] += tp[f][indx]
            tneg[-1] += tn[f][indx]
            fpos[-1] += fp[f][indx]
            fneg[-1] += fn[f][indx]
            
    #Begin by assuming that we call every observation an exceedance
    area = 0
    spec_last = 0
    sens_last = 1
    
    for k in range(len(specs)):
        sens = float(tpos[k]) / (tpos[k] + fneg[k])
        sp = float(tneg[k]) / (tneg[k] + fpos[k])
        area += (sp - spec_last) * sens
        sens_last = copy.copy(sens)
        spec_last = copy.copy(sp)
        
    return area

    
def OutputROC(raw):
    threshold = raw['threshold']
    
    tp = []
    tn = []
    fp = []
    fn = []
    sp = []
    
    for fold in range(len(raw['train'])):
        tpos = []
        tneg = []
        fpos = []
        fneg = []
        spec = []
        
        training_exc = np.array(raw['train'][fold] > threshold, dtype=bool)
        training_nonexc = np.array(raw['train'][fold] <= threshold, dtype=bool)
        thresholds = raw['fitted'][fold][training_nonexc]
        order = np.argsort(thresholds)
        
        for i in range(len(order)):
            k = order[i]
            test_exc = len(raw['validate'][fold] > thresholds[k])
            train_exc = len(raw['train'][fold] > thresholds[k])
            test_flag = len(raw['predicted'][fold] > thresholds[k])
            train_flag = len(raw['fitted'][fold] > thresholds[k])
            
            spec.append(float(i+1)/len(thresholds))
            tpos.append(np.where(raw['validate'][fold][raw['predicted'][fold] > thresholds[k]] > threshold)[0].shape[0])
            tneg.append(np.where(raw['validate'][fold][raw['predicted'][fold] <= thresholds[k]] <= threshold)[0].shape[0])
            fpos.append(np.where(raw['validate'][fold][raw['predicted'][fold] > thresholds[k]] <= threshold)[0].shape[0])
            fneg.append(np.where(raw['validate'][fold][raw['predicted'][fold] <= thresholds[k]] > threshold)[0].shape[0])
        
        tp.append(tpos)
        tn.append(tneg)
        fp.append(fpos)
        fn.append(fneg)
        sp.append(np.array(spec, dtype=float))
    
    specs = []
    [specs.extend(s) for s in sp]
    specs = np.sort(np.unique(specs))
    
    tpos = []
    tneg = []
    fpos = []
    fneg = []
    spec = []
    
    folds = len(tp)
    
    for s in specs:
        tpos.append(0)
        tneg.append(0)
        fpos.append(0)
        fneg.append(0)
        spec.append(s)
        
        for f in range(folds):
            indx = list(np.where(sp[f] >= s)[0])
            indx = indx[np.argmin(sp[f][indx])]
            
            tpos[-1] += tp[f][indx]
            tneg[-1] += tn[f][indx]
            fpos[-1] += fp[f][indx]
            fneg[-1] += fn[f][indx]
            
    result = np.array([spec, tpos, tneg, fpos, fneg], dtype=float)
    outfile = "../output/ROC.csv"
    np.savetxt(outfile, result.T, delimiter=",")
    
    

#What SpecificityChart wants: dict(specificity=specificity, tpos=tpos, tneg=tneg, fpos=fpos, fneg=fneg)
random.seed(seed)
print(locs)

for beach in locs:
    first = dict(zip(tasks, [True for k in tasks]))

    #Read the beach's data.
    datafile = beaches[beach]["file"]
    #datafile = VBTools.IO.ExcelOleDb(datafile, firstRowHeaders=True)
    #data = datafile.Read(datafile.GetWorksheetNames()[0])
    #datafile.CloseConnection()
    #if 'remove' in beaches[beach]: [headers, data] = utils.DotnetToArray(data, remove=beaches[beach]['remove'])
    #else: [headers, data] = utils.DotnetToArray(data)
    
    [headers, data] = utils.ReadCSV(datafile)
    data = [array.array('d', row) for row in data]
    if 'remove' in beaches[beach]:
        for item in beaches[beach]['remove']:
            item = item.lower()
            [row.pop(headers.index(item)) for row in data]
            headers.remove(item)
        
    #data = np.array(raw_table, dtype=float)
    #else: [headers, data] = utils.DotnetToArray(data)
    
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
        #print folds
        #folds = folds + 1
        validation = dict(zip(methods.keys(), [ValidationCounts() for method in methods]))
        
        ROC = dict(zip(methods.keys(), [{'train':[], 'fitted':[], 'validate':[], 'predicted':[], 'threshold':beaches[beach]['threshold']} for method in methods]))
        
        for f in range(cv_folds+1)[1:]:
            print "outer fold: " + str(f)
            #Break this fold into test and training sets.
            training_set = [data[i] for i in range(len(data)) if folds[i]!=f]
            inner_cv = utils.Partition(training_set, cv_folds)
            
            #Prepare the test set for use in prediction.
            test_set = [data[i] for i in range(len(data)) if folds[i]==f]
            test_dict = dict(zip(headers, [array.array('d', [row[i] for row in test_set]) for i in range(len(test_set[0]))]))
            
            #Run the modeling routines.
            for method in tasks:
                if first[method]:
                    out = open(output + ".".join([prefix, beach, method, "out"]), 'a')            
                    if seed: out.write("# Seed = " + str(seed) + "\n") 
                    out.write("# Site = " + beach + "\n")
                    out.write("# Method = " + method + "\n")
                    out.close()
                    first[method] = False
            
                #Run this modeling method against the beach data.
                result = Interface.Interface.Validate(training_set, beaches[beach]['target'], method=method, folds=inner_cv,
                                                        regulatory_threshold=beaches[beach]['threshold'], headers=headers, **methods[method])
                model = result[1]
                results = result[0]
                thresholding = dict(zip(['specificity', 'sensitivity', 'tpos', 'tneg', 'fpos', 'fneg'], Interface.Control.SpecificityChart(results)))
                
                #Store the thresholding information.
                #Open a file to which we will append the output.
                #out = open(output + beach + now + method + '_raw_models.out', 'a')
                #out.write("#" + method + "\n")                
                #print >> out, result
                
                #Close the output file and move on.
                #out.close()
                
                #Set the threshold for predicting the reserved test set
                #indx = [i for i in range(len(thresholding['fneg'])) if thresholding['fneg'][i] >= thresholding['fpos'][i] and thresholding['specificity'][i] > 0.8]
                #if not indx:
                #    indx = [i for i in range(len(thresholding['fneg'])) if thresholding['specificity'][i] > 0.8]
                indx = [int(i) for i in range(len(thresholding['fneg'])) if thresholding['fneg'][i] >= thresholding['fpos'][i]]
                if not indx: specificity = 0.9
                else: specificity = min([thresholding['specificity'][i] for i in indx])
                
                #Predict exceedances on the test set and add them to the results structure.
                model.Threshold(specificity)
                predictions = model.Predict(test_dict)
                truth = test_dict[beaches[beach]['target']]
                
                #These will be used to calculate the area under the ROC curve:
                order = sorted(range(len(truth)), key=truth.__getitem__)
                ROC[method]['validate'].append(truth)
                ROC[method]['predicted'].append(predictions)
                ROC[method]['train'].append(model.actual)
                ROC[method]['fitted'].append(model.fitted)
                
                #Calculate the predictive perfomance for the model
                tpos = len([i for i in range(len(predictions)) if predictions[i] > model.threshold and truth[i] > beaches[beach]['threshold']])  #sum((predictions>model.threshold) & (truth>beaches[beach]['threshold']))
                tneg = len([i for i in range(len(predictions)) if predictions[i] <= model.threshold and truth[i] <= beaches[beach]['threshold']])  #sum((predictions<=model.threshold) & (truth<=beaches[beach]['threshold']))
                fpos = len([i for i in range(len(predictions)) if predictions[i] > model.threshold and truth[i] <= beaches[beach]['threshold']])  #sum((predictions>model.threshold) & (truth<=beaches[beach]['threshold']))
                fneg = len([i for i in range(len(predictions)) if predictions[i] <= model.threshold and truth[i] > beaches[beach]['threshold']])  #sum((predictions<=model.threshold) & (truth>beaches[beach]['threshold']))
                
                #Add predictive performance stats to the aggregate.
                validation[method].tpos = validation[method].tpos + tpos
                validation[method].tneg = validation[method].tneg + tneg
                validation[method].fpos = validation[method].fpos + fpos
                validation[method].fneg = validation[method].fneg + fneg
            
                #Store the performance information.
                #Open a file to which we will append the output.
                out = open(output + ".".join([prefix, beach, method, "out"]), 'a')
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
                out.write("# fitted:\n")
                print >> out, model.fitted
                out.write("# actual:\n")
                print >> out, model.actual
                
                #Close the output file and move on.
                out.close()
            
        for m in tasks:
            #Store the performance information.
            #First, create a model for variable selection:
            data_dict = dict(zip(headers, [array.array('d', [row[i] for row in data]) for i in range(len(data[0]))]))
            model = Interface.Control.methods[m.lower()].Model(data=data_dict, target=beaches[beach]['target'], regulatory_threshold=beaches[beach]['threshold'], **methods[m])
            
            #Open a file to which we will append the output.
            out = open(output + ".".join([prefix, beach, m, "out"]), 'a')            
            out.write("# Area under ROC curve = " + str(AreaUnderROC(ROC[m])) + "\n")
            out.write("# aggregate.tpos = " + str(validation[m].tpos) + "\n")
            out.write("# aggregate.tneg = " + str(validation[m].tneg) + "\n")
            out.write("# aggregate.fpos = " + str(validation[m].fpos) + "\n")
            out.write("# aggregate.fneg = " + str(validation[m].fneg) + "\n")
            out.write("# variables: " + ", ".join(model.vars) + "\n")
            #out.write("# coefs: " + ", ".join([str(c) for c in model.coefs]) + "\n")
            out.write("# decision threshold: " + str(model.threshold) + "\n")
            
            #Close the output file and move on.
            out.close()
            
            #OutputROC(ROC[method])
            
            
        