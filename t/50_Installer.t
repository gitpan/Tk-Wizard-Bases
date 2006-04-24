#! perl
use vars qw/$VERSION/;
$VERSION = 3;	# 24 April 2006

use Test::More tests=>17;

no warnings;
use strict;

use lib '../lib';
use_ok("Tk::Wizard::Installer" =>  1.931);

our $TEMP_DIR = $ENV{TEMP} || $ENV{TMP} || "C:/temp" ;
mkdir("/temp",0777) if !-d $TEMP_DIR;
$TEMP_DIR =~ s/\\/\//g;

my $WAIT = 1;
my $MADE_DIR;
my $files = {
	'http://www.cpan.org/' => './cpan_index1.html',
	'http://www.cpan.org/' => './cpan_index2.html',
	'http://www.leegoddard.net' => './lee.html',
};

if (!-e '__perlwizardtest'){
	$MADE_DIR=1;
	$files->{'http://localhost/test.txt'} = '__perlwizardtest/test2.txt';
};


my $wizard = Tk::Wizard::Installer->new( -title => "Installer Test", );
isa_ok($wizard,'Tk::Wizard::Installer');
isa_ok($wizard->parent, "Tk::Wizard::Installer","Parent");

ok( $wizard->configure(
	-preNextButtonAction => sub { &preNextButtonAction($wizard) },
	-finishButtonAction  => sub { ok(1,'Finsihed') },
), 'Configure');

isa_ok($wizard->cget(-preNextButtonAction),"CODE");
isa_ok($wizard->cget(-finishButtonAction),"CODE");


# Create pages
#
my $SPLASH  = $wizard->addPage( sub{ page_splash ($wizard)} );
is($SPLASH,1,'Splash page is first');

ok($wizard->addDownloadPage(
	-wait => $WAIT,
	-files=> $files,
	#-on_error => 1,
	-no_retry => 1,
),'addDownloadPage');

ok( $wizard->addPage( sub {
	return $wizard->blank_frame(
		-wait	=> $WAIT,
		-title=>"Finished",
		-subtitle => "Please press Finish to leave the Wizard.",
		-text => "If you saw some error messages, they came from Tk::DirTree, and show "
		."that some of your drives are inacessible - perhaps a CD-ROM drive without "
		."media.  Such warnings can be turned off - please see the documentation for details."
	);
}),'Add finish page');

isa_ok($wizard->{wizardPageList},'ARRAY', 'Page list array');
is(scalar(@{$wizard->{wizardPageList}}), 3, 'Number of pages');
foreach (1..3){
	isa_ok($wizard->{wizardPageList}->[0], 'CODE', 'Page in list');
}

ok($wizard->Show, "Show");
Tk::Wizard::Installer::MainLoop();
ok(1,"Exited MainLoop");
unlink '__perlwizardtest' if $MADE_DIR;
exit;


sub page_splash { my $wizard = shift;
	my ($frame,@pl) = $wizard->blank_frame(
	-wait	=> $WAIT,
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



sub preNextButtonAction { return 1; }

__END__
