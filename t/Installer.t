#! perl -w
our $VERSION = 2;	# 27 May 2003

use strict;
use Cwd;

print "1..10\n";

use lib '../..';
use Tk::Wizard::Installer 0.023;
print "ok 1\n";

our $TEMP_DIR = $ENV{TEMP} || $ENV{TMP} || "C:/temp" ;
mkdir("/temp",0777) if !-d $TEMP_DIR;
$TEMP_DIR =~ s/\\/\//g;

my $MADE_DIR;

my $files = {
	'http://www.cpan.org/' => './cpan_index1.html',
	'http://www.cpan.org/' => './cpan_index2.html',
	'http://www.leegoddard.com/g/blue_head[2].gif' => 'big.gif',
};

if (!-e '__perlwizardtest'){
	$MADE_DIR=1;
	$files->{'http://localhost/test.txt'} = '__perlwizardtest/test2.txt';
};


#
# Instantiate Wizard
#

my $wizard = new Tk::Wizard::Installer(
	-title => "Installer Test",
	-style	=> 'top',
);

print ref $wizard eq "Tk::Wizard::Installer"? "ok 2\n" : "not ok 2\n";

$wizard->configure(
	-preNextButtonAction => sub { &preNextButtonAction($wizard) },
	-finishButtonAction  => sub { print "ok 9\n";  },
);


print ref $wizard->cget(-preNextButtonAction) eq "CODE"? "ok 3\n":"not ok 3\n";


#
# Create pages
#

our $SPLASH       	= $wizard->addPage( sub{ page_splash ($wizard)} );
print $SPLASH==1? "ok 4\n":"not ok 4\n";


print "ok 5\n";

$wizard->addDownloadPage(
	-files=> $files,
#	-on_error => 1,
);

our $user_chosen_dir;

our $GET_DIR 	= $wizard->addDirSelectPage (
	-variable => \$user_chosen_dir,
	-nowarnings	=> 1,
);
# Is page 3?
print $GET_DIR==3? "ok 6\n":"not ok 6 # $GET_DIR\n";

$_ = $wizard->addPage( sub {
	return $wizard->blank_frame(
		-title=>"Finished",
		-subtitle => "Please press Finish to leave the Wizard.",
		-text => "By the way, you selected the directory $user_chosen_dir.\n\n"
		."If you saw some error messages, they came from Tk::DirTree, and show "
		."that some of your drives are inacessible - perhaps a CD-ROM drive without "
		."media.  Such warnings can be turned off - please see the documentation for details."
	);
});
print $_? "ok 7\n":"not ok 7\n";

print ref $wizard->parent eq "Tk::Wizard::Installer"? "ok 8\n":"not ok 8\n";

$wizard->Show();
MainLoop;
print "ok 10\n";
unlink '__perlwizardtest' if $MADE_DIR;
exit;


sub page_splash { my $wizard = shift;
	my ($frame,@pl) = $wizard->blank_frame(-title=>"Installer Test",
	-subtitle=>"Testing Tk::Wizard::Installer $Tk::Wizard::Installer::VERSION",
	-text=>
		"This Wizard is a simple test of the Wizard, and nothing more.

No software will be installed, but you'll hopefully see a few things.

Latest addition: file download

"
	);
	return $frame;
}



sub preNextButtonAction { my $wizard = shift;
	local $_ = $wizard->currentPage;
	if (/^$GET_DIR$/){
		$_ = $wizard->callback_dirSelect( \$user_chosen_dir );
		if ($_==1){
			$_ = chdir $user_chosen_dir;
			if (not $_){
				$wizard->parent->messageBox(-icon=>'warning',-title=>'Oops',
				-text=>"Please choose a valid directory.");
			}
		}
		return $_? 1 : 0;
	}
	return 1;
}

__END__
