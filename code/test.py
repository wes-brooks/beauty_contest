'''
Created on May 27, 2011
@author: wrbrooks
'''
#Import the PLS modeling classes
import sys
import clr

#Set the separators 
_names = sys.builtin_module_names
if 'nt' in _names:
    sep = '\\'
    pathsep = ';'
else:
    sep = '/'
    pathsep = ':'

#Set the paths to IronPython based on the current working directory
sys.path.insert(0, sep.join(['..', 'bin', 'IronPython-2.7.4', 'Lib', 'site-packages']))
sys.path.insert(0, sep.join(['..', 'bin', 'IronPython-2.7.4', 'DLLs']))
sys.path.insert(0, sep.join(['..', 'bin', 'IronPython-2.7.4', 'Lib']))
sys.path.insert(0, sep.join(['..', 'bin', 'IronPython-2.7.4']))
sys.path.insert(0, sep.join(['..', 'bin']))

#We must link to the IronPython libraries before we can load the os module.
clr.AddReference("IronPython")
clr.AddReference("IronPython.Modules")
import os
import copy

#For some reason, numpy is unable to find the mtrand library on its own.
cwd = os.getcwd()
root = sep.join(cwd.split(sep)[:-1])
sys.path[4] = root + sep + sep.join(['bin', 'IronPython-2.7.4', 'Lib', 'site-packages'])
sys.path[3] = root + sep + sep.join(['bin', 'IronPython-2.7.4', 'DLLs'])
sys.path[2] = root + sep + sep.join(['bin', 'IronPython-2.7.4', 'Lib'])
sys.path[1] = root + sep + sep.join(['bin', 'IronPython-2.7.4'])
sys.path[0] = root + sep + sep.join(['bin'])

clr.AddReference("System.Data")

