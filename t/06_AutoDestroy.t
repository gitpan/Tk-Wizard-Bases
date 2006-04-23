#! perl -w

my $VERSION = do { my @r = (q$Revision: 1.4 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

use lib '../lib';
use Cwd;
use ExtUtils::testlib;
use Test::More tests => 20;

use strict;

BEGIN {
	use_ok('Tk::Wizard');
};

my $WAIT = 1;

ONE: {
	my $wizard = new Tk::Wizard( -title => "Test", );
	isa_ok($wizard, "Tk::Wizard");
	$wizard->configure(
		-preFinishButtonAction  => sub { ok(1) },
		-finishButtonAction  => sub { ok(1);  $wizard->destroy;},
	);
	isa_ok($wizard->cget(-finishButtonAction), "CODE");

	is(1, $wizard->addPage( sub{ page_splash ($wizard)} ));
	is(2, $wizard->addPage (sub{page_finish($wizard)} ));
	$wizard->Show;
	MainLoop;
	ok(1);
}

THREE: {
	my $wizard = new Tk::Wizard( -title => "Test", );
	isa_ok($wizard, "Tk::Wizard");
	$wizard->configure(
		-preFinishButtonAction  => sub { ok(1) },
		-finishButtonAction  => sub { ok(1);  },
	);
	is(1, $wizard->addPage( sub{ page_splash ($wizard)} ));
	is(2, $wizard->addPage (sub{page_finish($wizard)} ));
	$wizard->Show;
	MainLoop;
	isa_ok($wizard, "Tk::Wizard", "Wizard survived CloseWindowEventCycle");
	ok(1);
}


THREE: {
	my $wizard = new Tk::Wizard( -title => "Test", );
	isa_ok($wizard, "Tk::Wizard");
	is(1, $wizard->addPage( sub{ page_splash ($wizard)} ));
	is(2, $wizard->addPage (sub{page_finish($wizard)} ));
	$wizard->Show;
	MainLoop;
	isa_ok($wizard, "Tk::Wizard", "Wizard survived CloseWindowEventCycle");
	ok(1);
}


exit;

sub page_splash { my $wizard = shift;
	my $frame = $wizard->blank_frame(-title=>"Welcome to the Wizard Test 'pb'",
	-text=>
		"This script tests and hopefully demonstrates the 'postNextButtonAction' feature.\n\n"
		."When you click Next, a Tk::ProgressBar widget should slowly be udpated."
	);
	$frame->after($WAIT,sub{$wizard->forward});
	return $frame;
}

sub page_finish { my $wizard = shift;
	my ($frame,@pl) = $wizard->blank_frame(-title=>"Wizard Test 'pb' Complete",
		-text=> "Thanks for running this test.",
	);
	$frame->after($WAIT,sub{$wizard->forward});
	return $frame;
}

__END__

