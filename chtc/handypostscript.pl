#!/usr/bin/env perl

use File::Copy;
use File::Path;
use Getopt::Long;

my $defaultcompress = "tar -zcvf ";
my $thiscmpresstool = $defaultcompress;

my ($help, $remove, $compress, $usezip);
GetOptions (
                'help' => \$help,
				'remove=s' => \$remove,
				'compress=s' => \$compress,
				'usezip' => \$usezip,
);

if ( $help )    { help() and exit(0); }

my @patterns = ();


print "removing files based on a pattern or pattern list\n";
if(defined $remove) {
	@patterns = split /,/, $remove;
	foreach my $pat (@patterns) {
		system("rm *$pat*");
	}
}

print "making a subdirectory so only compressed files come back\n";
system("mkdir -p compressed");

print "compressing files with patterns\n";
my @patterns = ();
my @filestoacton = ();
my $findcmd = "ls ";
if(defined $compress) {
	@patterns = split /,/, $compress;
	foreach my $pat (@patterns) {
		$findcmd = $findcmd . "*$pat* ";
		print "findcmd now <$findcmd>\n";
	}
	@filestoacton = `$findcmd`; 
	foreach my $myfile (@filestoacton) {
		chomp($myfile);
		print "Compress file <$myfile>\n";
		if(defined $usezip) {
			# use zip
			system("zip -r comptessed $myfile");
		} else {
			#use tar
			system("$defaultcompress $myfile.tar.gz $myfile");
		}
		system("mv $myfile compressed");
	}
}

exit (0);


# =================================
# print help
# =================================

sub help 
{
    print "Usage: stage.pl --location=directory4folders --count=howmany
Options:
        --help                            See this
        --remove                          remove files with this pattern
        --compress                        compress files with this pattern
        --usezip                          default is tar but with this you
                                          can specify zip

        patterns can be a separated list like csv,txt and multiple actions will
        be taken for each pattern. The patern can be in the middle of the file
        name as we will match with wild cards on either side.

        rm *txt*
        rm *cvs*
        tar -zcvf filename.cvs.tar.gz *cvs*

        \n";
}

