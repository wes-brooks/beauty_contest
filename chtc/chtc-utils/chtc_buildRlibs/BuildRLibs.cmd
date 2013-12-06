# Transfer R Libraries 
# libraries which are required by other libraries must come first
# in the case below qtlnet requires qtl
transfer_input_files = qtl_1.16-6.tar.gz,qtlnet_0.9.4.tar.gz 

# Match dependency order for the argument that begins --rlibraries
# this is the only place the ordering matters
# The runtime choices currently available are:
# sl5-R-2.10.1, sl5-R-2.13.1 and sl5-R-2.14.0
arguments = --rversion=sl5-R-2.10.1  --rlibraries=qtl_1.16-6.tar.gz,qtlnet_0.9.4.tar.gz

# you will likely not need to change anything below here

executable = ./BuildRLibsRemote.pl
universe = vanilla
log = BuildRLibs.log
output = BuildRLibs.out
error = BuildRLibs.err
should_transfer_files   = yes
when_to_transfer_output = on_exit
+IsMatlabBuildJob = true
requirements = (IsMatlabBuildSlot =?= true) && (OpSysAndVer =?= "SL5")
Queue
