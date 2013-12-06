# you will need to add all m files needed for your entry point target(s)
transfer_input_files = bound_boot.m,bound_subsampling.m,g_func.m,g_func_sub.m,test_stat_boot.m,test_stat.m,test_stat_sub.m
# list out your entry point(s)
# if you require multiple executables, give the following a comma separated list
arguments = bound_boot.m

#You likely will not need to change below here
executable = ./CompileMatlabRemote.pl
universe = vanilla
log = CompileMatlab.log
output = CompileMatlab.out
error = CompileMatlab.err
should_transfer_files   = yes
when_to_transfer_output = on_exit
+IsMatlabBuildJob = true
requirements = (MatlabVersion =?= "R2011b") && IsMatlabBuildSlot && (OpSysAndVer =?= "SL6")
Queue
