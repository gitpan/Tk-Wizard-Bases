#! perl
use vars qw/$VERSION/;
$VERSION = 1;	# 17 May 2006

use Test::More tests=>19;

no warnings;
use strict;

use lib '../lib';
use_ok("Tk::Wizard::Installer" =>  1.931);

my $WAIT = 1;

our $TEMP_DIR = $ENV{TEMP} || $ENV{TMP} || "C:/temp" ;
mkdir("/temp",0777) if !-d $TEMP_DIR;
$TEMP_DIR =~ s/\\/\//g;
my $testdir = $TEMP_DIR.'/__perltk_wizard';
my $MADE_DIR;
if (!-d $testdir){
	$MADE_DIR=1;
	mkdir $testdir or BAIL_OUT ($!);
};
for (1..2){
	local *OUT;
	open OUT, ">".$testdir."/$_" or BAIL_OUT ($!);
	print OUT "Tk::Wizard::Installer Test. Please ignore or delete.\n\nThis is file $_\n\n".scalar(localtime)."\n\n";
	close OUT;
}
for (3..4){
	unlink $testdir."/$_"
}

my $wizard = Tk::Wizard::Installer->new(
	-title	=> "Installer Test",
);
isa_ok($wizard,'Tk::Wizard::Installer');
isa_ok($wizard->parent, "Tk::MainWindow","Parent");

ok( $wizard->configure(
	-preNextButtonAction => sub { &preNextButtonAction($wizard) },
	-finishButtonAction  => sub { ok(1,'Finished'); 1 },
), 'Configure');

isa_ok($wizard->cget(-preNextButtonAction),"Tk::Callback");
isa_ok($wizard->cget(-finishButtonAction),"Tk::Callback");


# Create pages
#
my $SPLASH  = $wizard->addPage( sub{ page_splash ($wizard)} );
is($SPLASH,1,'Splash page is first');

ok(
	$wizard->addFileListPage(
		-wait	=> $WAIT,
        -copy	=> 1,
        -from	=> [ $testdir."/1", $testdir."/2", ],
        -to		=> [ $testdir."/3", $testdir."/4",],
	)
, 'add File List page');

ok( $wizard->addPage( sub {
	return $wizard->blank_frame(
		-wait	=> $WAIT,
		-title=>"Finished",
		-subtitle => "Please press Finish to leave the Wizard.",
		-text => "Please report bugs via rt.cpan.org - thanks!"
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

for (1..2){
	unlink $testdir."/$_";
}
for (3..4){
	ok(-e($testdir."/$_"),'File copied');
	unlink $testdir."/$_" or diag "Can't remove $testdir/$_: $!";
}


unlink $testdir;

exit;


sub page_splash { my $wizard = shift;
	my ($frame,@pl) = $wizard->blank_frame(
		-wait		=> $WAIT,
		-title		=> "Installer Test",
		-subtitle	=> "Testing Tk::Wizard::Installer $Tk::Wizard::Installer::VERSION",
		-text		=> "Test Installer's addFileListPage feature for RT #19300."
	);
	return $frame;
}



sub preNextButtonAction { return 1; }

sub BAIL_OUT {
	diag @_;
	exit;
}

__END__
