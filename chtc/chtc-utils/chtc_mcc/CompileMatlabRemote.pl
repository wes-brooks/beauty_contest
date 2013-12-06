#! /usr/bin/env perl
use Getopt::Long;
use Cwd;
use Time::Local;
use strict;
use warnings;

my $compileargs = $ARGV[0];

#$ENV{PATH} = "/usr/local/bin/:" . "$ENV{PATH}";

#print "PATH now set to <$ENV{PATH}>\n";
my $cwd = getcwd();

my @alltargets = split /,/, $compileargs;
my $compileenv = "/home/gcc434/bin:.:/usr/local/bin:/bin:/usr/bin:/usr/X11R6/bin";
#system("whereis mcc");

my %moptions;
if(defined ($ARGV[1])) {
        foreach(split /,/, $ARGV[1]){
                $moptions{$_} = "";
        }
}

my $compilecmd = "";
if(exists $moptions{'multicore'}) {
	$compilecmd = "/usr/local/bin/mcc -m -R -nodisplay -R -nojvm ";
} else {
	$compilecmd = "/usr/local/bin/mcc -m -R -singleCompThread -R -nodisplay -R -nojvm ";
}
my @basedirs = ();
my $tarroot = "";
my $res = 0;

# always extract all tar files of the .tar.gz flavor
opendir DS, "." or die "Can not open dataset<.>\n";
foreach my $subfile (readdir DS){
	next if($subfile =~ /^\.\.?$/);
	if($subfile =~ /^(.*?)\.tar\.gz/){
		$tarroot = $1;
		$res = system("tar -zxf $subfile");
		if($res != 0) {
			die "Extraction of $subfile  failed\n";
		}
		if( -d $tarroot) {
			push @basedirs, $tarroot;
		}
	# hmmmm why do we care about deep here
	} elsif(exists $moptions{'deep'}) {
		print "$subfile not tar file\n";
	}
}
if(exists $moptions{'java'}){
	$compilecmd =~ s/-R -nojvm //;
}
if(exists $moptions{'deep'}){
	foreach my $dir(@basedirs){
		$compilecmd .= "-a $dir ";
	}
}
if(exists $moptions{'mex'}){
        $compilecmd = "/usr/local/bin/mex ";
}
my $cmd = "";

my $unsetdef;
if(exists $ENV{PATH}) {
    $ENV{PATH} = $compileenv . ":" . $ENV{PATH};
} else {
    $ENV{PATH} = $compileenv;
}
$ENV{USER} = "bt";
$ENV{TERM} = "xterm";
$ENV{SHELL} = "/bin/bash";
$ENV{LOGNAME} = "bt";
$ENV{HOME} = "$cwd";
$ENV{PWD} = ".";
#$ENV{DISPLAY} = unsetdef;
$ENV{HOSTNAME} = "submit.chtc.wisc.edu";
$ENV{SSH_TTY} = "/dev/pts/4";
$ENV{LANG} = "en_US.UTF-8";
$ENV{PWD} = "/tmp";
if(exists $ENV{LD_LIBRARY_PATH}) {
    $ENV{LD_LIBRARY_PATH} = "/home/gcc434/mpfr2_3_1/lib:/home/gcc434/gmp4_1_2/lib:$ENV{LD_LIBRARY_PATH}";} else {
    $ENV{LD_LIBRARY_PATH} = "/home/gcc434/mpfr2_3_1/lib:/home/gcc434/gmp4_1_2/lib";
}

system("mkdir -p $cwd/.matlab");
print "MCC compiletime path = <<<<$ENV{PATH}>>>>\n";

my $matlabsources = "matlabsources.tar.gz";
if(-f "$matlabsources") {
	system("tar -zxf $matlabsources");
}

#print "Have these files handy.\n";
system("printenv");

system("uname -a");
system("which gcc");
system("ls -lh");

my $fullmexcmd = "$compilecmd";
my $ret = 0;
if(exists $moptions{'mex'}){
	print "Great looking at mfiles and ignoring mtargets in building mex file\n";
	my @mfiles = split /,/, $ARGV[0];
	foreach my $file ( @mfiles ) {
		$fullmexcmd = $fullmexcmd . " $file";
	}
	print "About to run <$fullmexcmd>\n";
	$ret = system("$fullmexcmd");
	if($ret != 0){
		print "Mex File Creation failed for <$fullmexcmd>: Recover!\n";
		system("touch RETRYCOMPILE");
		exit(1);
	}
} else {
	foreach my $targ (@alltargets) {
		my @targetparts = split /\./, $targ;
		#print "My base name = $targetparts[0]\n";
		#print "Removing <$targetparts[0]>\n";
		$cmd = $compilecmd . $targ;
		print "About to do this compile: <<$cmd>>\n";
		my $ret = system("$cmd");
		print "Return from compile request is <<<$ret>>>\n";
		if(!(-f "$targetparts[0]")){
			print "Compile failed for <$targ>: Recover!\n";
			system("touch RETRYCOMPILE");
			exit(1);
		}
	}
}


#print "After, have these files.\n";
#system("ls");
#print "Bye\n";
system("touch COMPILEDONE");
exit(0);
