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
my $FAILEDCONFIGEDIT = 14;

my ($help, $cmdtorun, $unique, $pversion, $pmodules, $make);
GetOptions
(
	'help' => \$help,
	'pversion=s' => \$pversion,
	'pmodules=s' => \$pmodules,
	'make=s' => \$make,
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
if( !(defined $pversion) || !(defined $pmodules)) {
	print "Usage: BuildPythonmodulesRemote.pl --pversion=xxxxx --pmodules=a,b,c,d\n";
	exit($BADUSAGE);
}

#print "Running: <$pversion $pmodules $unique>\n";
#R
my $location = getcwd();

my $verision = "1.0"; # Euclid adjustments

my $dbinstalllog =  "BuildPythonModules.build$$.out";
print "Trying to open logfile... $dbinstalllog\n";
#open(OLDOUT, ">&STDOUT");
#open(OLDERR, ">&STDERR");
open(STDOUT, ">>$dbinstalllog") or die "Could not open $dbinstalllog: $!";
open(STDERR, ">&STDOUT");
select(STDERR);
 $| = 1;
 select(STDOUT);
  $| = 1;

print "Running here: ";
system("hostname");

my $begintime = time();
my $endtime = time();
my $intervalstart = time();
my $intervalstop = time();

#print "\n\n ******** My Verison = <<<<$pversion>>>> curl targets <<<<$curltargetcount>>>>******** \n\n";


#system("df -k");
system("pwd;ls");

my @removelist = ();
my $infofile = "$pversion" . "_INFO";
my $localproxy = "no";
my $curlres = 0;

my $localcurlres = FetchViaCurl("$infofile","","same");
if($localcurlres != 0) {
	exit($FAILEDCURLSLIBS);
}

push @removelist, $infofile;

my %versioninfo = ();
ParseOptions($infofile,\%versioninfo);

my $phome = "$versioninfo{treeroot}";
my $pbuilt = "$versioninfo{tarball}";
my $runtime = "$versioninfo{runtime}";
my $checksum = "$versioninfo{checksum}";

my $saveinfo = "";
if($checksum =~ /^.*?\/.*?\/(.*)$/) {
	print "New file name is <$1>\n";
	$saveinfo = $1;
} else {
	die "expecting xxxxxxx/xxxxxxxx/checksumnameininfofile\n";
}


print "Path base to $checksum is $1\n";
## get the requested python
print "Info file: $phome $pbuilt $runtime $checksum\n";
$curlres = FetchViaCurl("$runtime", "", "$pbuilt");

if($curlres != 0) {
	system("rm $pbuilt");
    print "Fetch of runtime <$pbuilt> failed via curl\n";
	HandleRemoves();
	exit($FAILEDCURLRUNTIME);
}

push @removelist, $pbuilt;
## Allow for download of matching checksum 
my $sha1res = 0;
# rules for right checksum file is 
if(exists $versioninfo{checksum}) {

	$curlres = FetchViaCurl("$checksum", "", "$saveinfo");
my $BADUSAGE = 10;
	if($curlres != 0) {
		system("rm $pbuilt");
    	print "Fetch of runtime <$saveinfo> failed via curl\n";
		exit($FAILEDCURLCHECKSUM);
	}


	print "Checking runtime $pbuilt against checksum file $saveinfo\n";
	$sha1res = system("sha1sum -c $saveinfo");
	push @removelist, $saveinfo;
	#system("rm $saveinfo"); # no reason to return this
} else {
	HandleRemoves();
	exit($NOCHECKSUM);
}


if($sha1res != 0) {
	print "sha1 checksum validation failed\n";
	HandleRemoves();
	exit($CHECKSUMFAILED);
}

# ok set this python up

if(!(-f $pbuilt)) {
	HandleRemoves();
    die "No prebuilt Python to install locally<$pbuilt>.....\n";
} else {
    # prepare a Python for this sandbox
    system("tar -zxf $pbuilt");
    print "doing python setup from here:\n";
	$ENV{PYTHONHOME} = "$location/$phome";
	$ENV{PYTHONPATH} = "$location/$phome:$location/site-packages/lib/python2.7/site-packages";
	$ENV{PATH} = "$location/$phome/bin:$ENV{PATH}";
    system("pwd;ls");
    system("which python");
	system("printenv");
}

# fix bad interpreter localion in python2.7-config
# a makefile build needs this
my  $configfile = "$location/$phome/bin/python2.7-config";
my  $configfilenew = "$location/$phome/bin/python2.7-config.new";
my $scan = "";
open( IN, "<$configfile") or die "Can not open <$configfile>:$!\n";
open( OUT, ">$configfilenew") or die "Can not open <$configfilenew>:$!\n";
while(<IN>) {
	chomp ();
	$scan = $_;
	if ($scan =~ /^#!.*$/) {
		print "*************************** Found Interpreter line *********************!\n";
		print OUT "#!$location/$phome/bin/python2.7\n";
	} elsif($scan =~ /^(\s*)libs\.append.*$/) {
		print "****************Found -lpython line ******************************\n";
		print OUT "$1libs.append(\'-L $location/$phome/lib -lpython\'+pyver)\n";
	} else {
		print OUT "$scan\n";
	}
}

close(IN);
close(OUT);



# take a look at the edit then remove
system("cp $configfilenew $location");

my $mvres = system("mv $configfile $configfile.orig");
if ($mvres != 0) {
	print "Saving original python2.7-config failed(non fatal)\n";;
}

$mvres = system("mv $configfilenew $configfile");
if ($mvres != 0) {
	HandleRemoves();
	print "Saving original python2.7-config failed(fatal)\n";
	exit ($FAILEDCONFIGEDIT);
}

my $configchmod = system("chmod 755 $configfile");
if ($configchmod != 0) {
	print "CHMOD of $configfile failed......\n";;
}

my @modules = split /,/, $pmodules;

my $ret = 0;
sleep(60);

system("ls -lh");
if(defined $make) {
	print "Build with make triggered!\n";
	my @makes = split /,/, $make;
	foreach my $lib (@makes) {
		print "................................................................\n";
	    print "Building <$lib> with make\n";
		print "................................................................\n";
		my $basename = "";
		if($lib =~ /^(.*?)\.tar\.gz$/) {
			$basename = $1;
			print "................................................................\n";
	    	print "Extracting <$lib> Starting Now\n";
			print "................................................................\n";
			system("tar -zxf $lib");
			system("ls -lh");
			if(!(-d "$basename")) {
				die "Expected module install location<$basename> does not exist\n";
			} else {
				chdir("$basename");
				print "Before make build environment is:\n";
				system("printenv");
				$ret = system("make");
	    		if($ret != 0) {
	        		print "Python module build(using make) for $lib failed!!!!\n";
	        		system("touch RETRYCOMPILE");
					HandleRemoves();
	        		exit(1);
	    		}
				#system("mkdir -p $location/site-packages");
				#system("mkdir -p $location/site-packages/lib");
				#system("mkdir -p $location/site-packages/lib/python2.7");
				#system("mkdir -p $location/site-packages/lib/python2.7/site-packages");
				#print "................................................................\n";
	    		#print "Building for <$lib> Starting Now\n";
				#print "................................................................\n";
				#system("python setup.py install --prefix=$location/site-packages");
	    		#if($ret != 0) {
					#print "................................................................\n";
	    			#print "Building for <$lib> FAILED - Read Messages above!\n";
	    			#print "Look for something like:<raise ImportError(\"statsmodels requires pandas\")>\n";
					#print "................................................................\n";
	        		#print "Python module build for $lib failed!!!!\n";
	        		#system("touch RETRYCOMPILE");
					#HandleRemoves();
	        		#exit(1);
	    		#}
				#print "................................................................\n";
	    		#print "Building for <$lib> Worked\n";
				#print "................................................................\n";
				chdir("$location");
				#packageSite();
			}
		} else {
			print "$lib is an unexpected module name\n";
		}
	}
} else {

	foreach my $lib (@modules) {
		print "................................................................\n";
	    print "Building <$lib>\n";
		print "................................................................\n";
		my $basename = "";
		if($lib =~ /^(.*?)\.tar\.gz$/) {
			$basename = $1;
			print "................................................................\n";
	    	print "Extracting <$lib> Starting Now\n";
			print "................................................................\n";
			system("tar -zxf $lib");
			system("ls -lh");
			if(!(-d "$basename")) {
				die "Expected module install location<$basename> does not exist\n";
			} else {
				chdir("$basename");
				print "Before build environment is:\n";
				system("printenv");
				$ret = system("python setup.py build");
	    		if($ret != 0) {
	        		print "Python module build for $lib failed!!!!\n";
	        		system("touch RETRYCOMPILE");
					HandleRemoves();
	        		exit(1);
	    		}
				system("mkdir -p $location/site-packages");
				system("mkdir -p $location/site-packages/lib");
				system("mkdir -p $location/site-packages/lib/python2.7");
				system("mkdir -p $location/site-packages/lib/python2.7/site-packages");
				print "................................................................\n";
	    		print "Building for <$lib> Starting Now\n";
				print "................................................................\n";
				system("python setup.py install --prefix=$location/site-packages");
	    		if($ret != 0) {
					print "................................................................\n";
	    			print "Building for <$lib> FAILED - Read Messages above!\n";
	    			print "Look for something like:<raise ImportError(\"statsmodels requires pandas\")>\n";
					print "................................................................\n";
	        		print "Python module build for $lib failed!!!!\n";
	        		system("touch RETRYCOMPILE");
					HandleRemoves();
	        		exit(1);
	    		}
				print "................................................................\n";
	    		print "Building for <$lib> Worked\n";
				print "................................................................\n";
				chdir("$location");
				packageSite();
			}
		} else {
			print "$lib is an unexpected module name\n";
		}
	}
}

system("ls -lH");
system("touch COMPILEDONE");

HandleRemoves();

exit(0);

sub packageSite
{
system("ls -R site-packages");
	print "Making tar archive......\n";
	chdir("site-packages");
	my $ret = 1;
	if($pversion =~ /sl6/) {
		$ret = system("tar -zcf ../sl6-SITEPACKS.tar.gz lib");
	}elsif($pversion =~ /sl5/) {
		$ret = system("tar -zcf ../sl5-SITEPACKS.tar.gz lib");
	}else {
		$ret = system("tar -zcf ../SITEPACKS.tar.gz lib");
	}
	if($ret != 0) {
    	print "site-packages packaging failed!!!\n";
    	system("touch RETRYCOMPILE");
    	exit(1);
	}
	chdir("$location");
}

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
		print "Curl attempt:<$curlcmd>\n";
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
		my $cmd = "curl -H \"Pragma:\" -o $target $url$target";
		print "Trying this: $cmd\n";
		system("$cmd");
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
#	'pbuilt=s' => \$pbuilt,
#	'installfrom=s' => \$installfrom,
#	'cmdtorun=s' => \$cmdtorun,
#	'unique=s' => \$unique,

sub help
{
	print "Usage: BuildPythonmodulesRemote.pl --pversion=xxxxx --pmodules=a,b,c,d\n";
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
