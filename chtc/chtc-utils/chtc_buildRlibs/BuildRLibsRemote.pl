#! /usr/bin/env perl
use Cwd;
use Getopt::Long;
use File::Basename;
use strict;
use warnings;

$ENV{PATH} = "/usr/local/bin:/usr/kerberos/bin:/usr/bin:/bin";

# Some defines for our returns
my $ALLSWELL = 0;
my $FAILEDCURLWRAPPER = 1;
my $FAILEDCURLRUNTIME = 2;
my $CHECKSUMFAILED = 3;
my $NORUNTIME = 4;
my $UNTARRUNTIME = 5;
my $UNTARJOBDATA = 6;
my $FAILEDRLIBUNTAR = 7;
my $FAILEDRUN = 8;
my $MISSINGOUTPUT = 9;
my $BADUSAGE = 10;
my $NOCHECKSUM = 11;
my $FAILEDCURLCHECKSUM = 12;
my $FAILEDCURLSLIBS = 13;

my ($help, $cmdtorun, $unique, $rversion, $rlibraries, $shlib);
GetOptions
(
	'help' => \$help,
	'rversion=s' => \$rversion,
	'rlibraries=s' => \$rlibraries,
	'shlib' => \$shlib,
	'unique=s' => \$unique,
);


if(defined $help) {
	print "Help defined\n";
	help();
	exit(0);
}

my $DEBUG = 0;
#DebugOn();

my $stampfilename = "";
if(defined $unique) {
	$stampfilename = "AuditLog.$unique";
} else {
	$stampfilename = "AuditLog";
}

# test for all needed arguements prior to job args
if( !(defined $rversion) || !(defined $rlibraries)) {
	print "Usage: BuildRLibs.pl --rversion=xxxxx --rlibraries=a,b,c,d [--shlib]\n";
	exit($BADUSAGE);
}

#print "Running: <$rversion $rlibraries $unique>\n";
#R
my $location = getcwd();
my $renviron;

my $verision = "1.0"; # Euclid adjustments

#my $dbinstalllog =  "BuildRLibs.$unique.out";
#print "Trying to open logfile... $dbinstalllog\n";
#open(OLDOUT, ">&STDOUT");
#open(OLDERR, ">&STDERR");
#open(STDOUT, ">>$dbinstalllog") or die "Could not open $dbinstalllog: $!";
#open(STDERR, ">&STDOUT");
#select(STDERR);
 #$| = 1;
 #select(STDOUT);
  #$| = 1;

print "Running here: ";
system("hostname");

my $begintime = time();
my $endtime = time();
my $intervalstart = time();
my $intervalstop = time();

#my @curltargets = (
	#"http://proxy.chtc.wisc.edu/SQUID/",
	#"http://proxy-3.chtc.wisc.edu/SQUID/",
	#"http://proxy.chtc.wisc.edu/SQUID/",
	#"http://proxy-3.chtc.wisc.edu/SQUID/",
	#"http://proxy.chtc.wisc.edu/SQUID/",
	#"http://proxy-3.chtc.wisc.edu/SQUID/",
	#"http://proxy.chtc.wisc.edu/SQUID/",
	#"http://proxy-3.chtc.wisc.edu/SQUID/",
	#"http://proxy.chtc.wisc.edu/SQUID/",
	#"http://proxy-3.chtc.wisc.edu/SQUID/",
#);

#my $curltargetcount = @curltargets;

#system("printenv");
#print "\n\n ******** My Verison = <<<<$rversion>>>> curl targets <<<<$curltargetcount>>>>******** \n\n";


#system("df -k");
#system("pwd");

my @removelist = ();
my $infofile = "$rversion" . "_INFO";
my $localproxy = "no";
my $curlres = 0;

my $localcurlres = FetchViaCurl("$infofile","","same");
if($localcurlres != 0) {
	exit($FAILEDCURLSLIBS);
}

push @removelist, $infofile;

my %versioninfo = ();
ParseOptions($infofile,\%versioninfo);

my $Rinstallfrom = "$versioninfo{treeroot}";
print "Rinstallfrom <$Rinstallfrom>\n";
my $Rlocation = "$location/$versioninfo{treeroot}";

my $Rprebuilt = "$versioninfo{tarball}";
my $tarball = $Rprebuilt;

$curlres = FetchViaCurl($Rprebuilt, "", "same");

if($curlres != 0) {
	system("rm $Rprebuilt");
    print "Fetch of runtime <$Rprebuilt> failed via curl\n";
	HandleRemoves();
	exit($FAILEDCURLRUNTIME);
}

push @removelist, $Rprebuilt;
## Allow for download of matching checksum 
my $sha1res = 0;
# rules for right checksum file is basename_input_checksum.txt
if($tarball =~ /(.*?)\.tar\.gz/) {
	my $basename = $1;
	$basename = $basename . "_input_checksum.txt";

	$curlres = FetchViaCurl($basename, "", "same");
	if($curlres != 0) {
		system("rm $Rprebuilt");
    	print "Fetch of runtime <$basename> failed via curl\n";
		exit($FAILEDCURLCHECKSUM);
	}

	print "Checking runtime $tarball against checksum file $basename\n";
	$sha1res = system("sha1sum -c $basename");
	system("rm $basename"); # no reason to return this
} else {
	HandleRemoves();
	exit($NOCHECKSUM);
}


if($sha1res != 0) {
	print "sha1 checksum validation failed\n";
	HandleRemoves();
	exit($CHECKSUMFAILED);
}

if(!(-f $Rprebuilt)) {
	HandleRemoves();
    die "No prebuilt R to install locally<$Rprebuilt>.....\n";
} else {
    # prepare an R for this sandbox
    system("tar -zxf $Rprebuilt");
    chdir("$Rinstallfrom");
    print "doing install from here:\n";
    system("pwd");
    #print "About to execute <make prefix=$Rlocation install>\n";
    #system("make prefix=$Rlocation install");
    chdir("$location");
	my $Rwrapper = "$location/$Rinstallfrom/bin/R";
    my $RwrapperTemp = "$Rwrapper" . ".new";
	print "Old wrapper<$Rwrapper> new <$RwrapperTemp>\n";
    my $looking = 1;
    my $line = "";
    open(RWRP,"<$Rwrapper") or die "Can not open<$Rwrapper>:$!\n";
    open(TEMP,">$RwrapperTemp") or die "Can not open <$RwrapperTemp>:$!\n";
    while(<RWRP>) {
        chomp();
        $line = $_;
        if($looking == 1) {
            if($line =~ /^R_HOME_DIR=(.*)$/) {
                print TEMP "R_HOME_DIR=\"$location/$Rinstallfrom\"\n";
                $looking = 0;
            } else {
                print TEMP "$line\n";
            }
        } else {
            print TEMP "$line\n";
        }
    }
    close(RWRP);
    close(TEMP);
    # lets see what we did
    #system("cp $RwrapperTemp $location");
    # replace original R wrapper
    my $save = $Rwrapper . ".orig";
    system("mv $Rwrapper $save");
    system("mv $RwrapperTemp $Rwrapper");
    system("chmod 775 $Rwrapper");
    system("ls -lt $location/$Rinstallfrom/bin/");
}

#$ENV{HOME} = $location;
system("mkdir -p $location/RR");
system("mkdir -p $location/RR/library");

my $localRsources = "Rsources.tar.gz";
if(-f "$localRsources") {
    # extract needed package source
    system("tar -zxf $localRsources");
}

my @libraries = split /,/, $rlibraries;

my $libname = "";
if(defined $shlib) {
	# if we are building a C shared library
	# extract base name of first file and create
	# the execute string
	my $cmd = "$Rlocation/bin/R CMD SHLIB ";
	if($libraries[0] =~ /(.*?)\.c/) {
		print "Setting library bane name to <$1>\n";
		$libname = $1;
	} else {
		die "Building R shared C library. no .c file<$libraries[0]>\n";
	}
	foreach my $cfile (@libraries) {
		$cmd = $cmd . "$cfile ";
	}
	print "Shared library base name <$libname>\n";
	my $ret = system("$cmd");
	print "$rversion\n";
	system("ls");
	if($rversion =~ /sl6/) {
		system("mv $libname.so sl6-$libname.so");
	} else {
		system("mv $libname.so sl5-$libname.so");
	}
} else {

	foreach my $lib (@libraries) {
	    print "Building <$lib>\n";
	    my $cmd = "$Rlocation/bin/R CMD INSTALL --preclean -l $location/RR/library $lib";
	    #print "Package build:<$cmd>\n";
	    my $ret = system("$cmd");
	    if($ret != 0) {
	        print "R library build of $lib failed!!!!\n";
	        system("touch RETRYCOMPILE");
			HandleRemoves();
	        exit(1);
	    }
	}

	#system("ls -R RR");
	#print "Making tar archive......\n";
	my $ret = 1;
	if($rversion =~ /sl6/) {
		$ret = system("tar -zcf sl6-RLIBS.tar.gz RR");
	}else {
		$ret = system("tar -zcf sl5-RLIBS.tar.gz RR");
	}
	if($ret != 0) {
	    print "R library build of @libraries failed!!!!\n";
	    system("touch RETRYCOMPILE");
		HandleRemoves();
	    exit(1);
	}
}
system("touch COMPILEDONE");

HandleRemoves();

exit(0);

sub HandleRemoves
{
	foreach my $file (@removelist) {
		print "Cleaning up <$file>\n";
		system("rm -rf $file");
	}
}



#NOTE: When we want a major file, its at the top level. But we could be seeking
#SOAR project specific files which are down a path. In those cases we have to save
#the actual file to the current directory

sub FetchViaCurl
{
	my $target = shift;
	my $unique = shift;
	my $savename = shift;

	my $tries = 30;
	my $trycount = 0;
	my $sleeptime = 6;
	my $starttime = time();
	
	#my $random = time();
	my $url = "";
	#print "Random = $random\n";
	#my $urlindex = $random % $curltargetcount;
	#print "Using curl server index <<$urlindex>>\n";
	if($localproxy eq "yes") {
		$url = "http://10.0.3.5/SQUID/";
	} else {
		$url = "http://proxy.chtc.wisc.edu/SQUID/"
	}
	print "URL: <<$url>>\n";

	while($trycount < $tries) {
		my $curlcmd = "";
		if($savename eq "same") {
			$curlcmd = "curl -H \"Pragma:\" -o $target $url$target";
		} else {
			$curlcmd = "curl -H \"Pragma:\" -o $savename $url$target";
		}
		#print "Curl attempt:<$curlcmd>\n";
		$curlres = system("$curlcmd");
		# trace data per attempt
		my $stoptime = time();
		my $elapsed = $stoptime - $starttime;
		my $fetchfile = "$url$target";
		my $result = $curlres >>=8;
		my $signal = $curlres & 255;
		write_audit_message("CURL",(url=>$fetchfile,time=>$elapsed,signal=>$signal,result=>$result));
		if($curlres != 0) {
			$trycount += 1;
			sleep($sleeptime);
		} else {
			last;
		}
	}
	#print "Curl error <$curlres>\n";
	return($curlres);
}

#	I don't care strongly about the filename, but as a straw man:
#	"AuditLog.$unique"?

#	I propose the following for the records:

#	TIMESTAMP TYPE key=value key=value key=value

#	- TIMESTAMP can be anything easy to parse.
#	- TYPE is unique identified for that type of record
#	- keys and values are forbidden from having spaces in them (to
#	  simplify parsing).  We'll probably want some sort of simple
#	  escaping mechanism.  Perhaps s/\\/\\\\/g; s/_/\\_/g; s/ /_/g;
#	- Might want to sort keys within a given record.

#	so for example
#	2011-04-18 14:35 CURL duration=32 url=http://www.example.com/foo/bar result=1
#	2011-04-17 15:22 EXIT cmd=R return=0 signal=7


#	proposed API:

#	sub write_audit_message {
#	my($type, %keys) = @_;
#	# Write log here.
#	}


sub write_audit_message {
	open(STAMP,">>$stampfilename");
	my($type, %classad) = @_;
	print STAMP ( timestamp(), " $type ");
	foreach my $key (sort keys (%classad)) {
		my $filter = $classad{$key};
		$filter =~ s/>/GT/g;
		print STAMP "$key=<$filter> ";
	}
	print STAMP "\n";
	close(STAMP);
}

sub timestamp {
    return scalar localtime();
}

# can we find a private interface to squid server

sub FetchViaCurlTest
{
	my $target = shift;
	my $url = shift;
	my $unique = shift;

	my $tries = 30;
	my $trycount = 0;
	my $sleeptime = 6;
	my $starttime = time();
	
	while($trycount < $tries) {
		$curlres = system("curl -H \"Pragma:\" -o $target $url$target");
		# trace data per attempt
		my $stoptime = time();
		my $elapsed = $stoptime - $starttime;
		my $fetchfile = "$url$target";
		my $result = $curlres >>=8;
		my $signal = $curlres & 255;
		write_audit_message("CURL",(url=>$fetchfile,time=>$elapsed,signal=>$signal,result=>$result));
		if($curlres != 0) {
			$trycount += 1;
			sleep($sleeptime);
		} else {
			last;
		}
	}
	#print "Curl error <$curlres>\n";
	return($curlres);
}


#	'help' => \$help,
#	'new' => \$new,
#	'type=s' => \$type,
#	'tarball=s' => \$tarball,
#	'installfrom=s' => \$installfrom,
#	'cmdtorun=s' => \$cmdtorun,
#	'unique=s' => \$unique,

sub help
{
	print "Usage: BuildRLibs.pl --rversion=xxxxx --rlibraries=a,b,c,d\n";
}

sub MachineAdTest
{
    my $pattern = shift;
    my $answer = "no";
    my $line = "";
    #print "MachineAdTest: looking for <$pattern>\n";

    open(MA,"<.machine.ad") or return($answer);
    while(<MA>) {
        chomp();
        $line = $_;
        if($line =~ /^.*$pattern.*$/) {
            $answer = "yes";
        }
    }
    return($answer);
}


# =================================
# ParseOptions will hash entries desired to tune automatic
# updates things like if a new version is wanted, what limit count
# for first run, run on existing(reset) or new only data sets,
# if matlab, which m files to compile..... etc
#
# A hesh reference must be passed in
# =================================

sub ParseOptions
{
    my $options = shift;
    my $hashref = shift;

    my $jobadsplus = "";
    debug("ParseOptions on file <$options>\n");
	if(!(-f $options)) {
        print "No update configuration file present at <$options>\n";
        ${$hashref}{"success"} = 0;
        return(0);
    }

    open(NORUNS,"<$options") || die "Can not open <$options>
: $!\n";
    while(<NORUNS>) {
        if($_ =~ /^(\w+)\s*=\s*(.*)\s*/) {
            debug("Option $1 = $2\n");
            next if ( $1 eq "version" );
            ${$hashref}{$1} = $2;
        } elsif($_ =~ /^(\+.*)/) {
            if($jobadsplus eq "") {
                $jobadsplus = "$1"
            } else {
                $jobadsplus = $jobadsplus . ",$1"
            }
        } else {
            print "no match: $_";
        }

    }
	close(NORUNS);
    if($jobadsplus ne "") {
        ${$hashref}{JobAds} = $jobadsplus;
    }

    ${$hashref}{"success"} = 1;

    debug("Leaving ParseOptions - success == ${$hashref}{\"success\"}\n");
}

#####################################################
#
# Debug code
#
#####################################################

sub debug
{
    my $string = shift;
    print( "DEBUG ", timestamp(), ": $string" ) if $DEBUG;
}

sub DebugOn
{
    $DEBUG = 1;
}

sub DebugOff
{
    $DEBUG = 0;
}
