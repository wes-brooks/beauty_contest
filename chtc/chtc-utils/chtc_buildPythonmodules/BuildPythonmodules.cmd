# Transfer R Libraries 
# libraries which are required by other libraries must come first
# in the case below qtlnet requires qtl
transfer_input_files = 	matplotlib-1.1.0.tar.gz,numpy-1.6.2.tar.gz

# Match dependency order for the argument that begins --pmodules
# this is the only place the ordering matters
# The runtime choices currently available are:
# sl5-Python-2.7.3
arguments = --pversion=sl5-Python-2.7.3  --pmodules=numpy-1.6.2.tar.gz,matplotlib-1.1.0.tar.gz

# you will likely not need to change anything below here

executable = ./BuildPythonmodulesRemote.pl
universe = vanilla
log = buildPythonModes.log
output = buildPythonModes.out
error = buildPythonModes.err
should_transfer_files   = yes
when_to_transfer_output = on_exit
+IsMatlabBuildJob = true
requirements = (OpSysAndVer =?= "SL5") && (IsMatlabBuildSlot =?= true)
Queue
