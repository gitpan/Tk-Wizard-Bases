#! perl -w
use vars qw/$VERSION/;
$VERSION = 2.2;	# 06 May 2005

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
	-image_dir	=> 'lib/Tk/Wizard/images/',
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
my $SPLASH  = $wizard->addPage( sub{ page_splash ($wizard)} );
print $SPLASH==1? "ok 4\n":"not ok 4\n";


print "ok 5\n";

$wizard->addDownloadPage(
	-files=> $files,
	#-on_error => 1,
	-no_retry => 1,
);

print "ok 6\n";

$_ = $wizard->addPage( sub {
	return $wizard->blank_frame(
		-wait	=> 1,
		-title=>"Finished",
		-subtitle => "Please press Finish to leave the Wizard.",
		-text => "If you saw some error messages, they came from Tk::DirTree, and show "
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
	my ($frame,@pl) = $wizard->blank_frame(
	-wait	=> 1,

	-title=>"Installer Test",
	-subtitle=>"Testing Tk::Wizard::Installer $Tk::Wizard::Installer::VERSION",
	-text=>
		"This Wizard is a simple test of the Wizard, and nothing more.

No software will be installed, but you'll hopefully see a few things.

Latest addition: file download

"

	);
	return $frame;
}



sub preNextButtonAction {
	return 1;
}

__END__
