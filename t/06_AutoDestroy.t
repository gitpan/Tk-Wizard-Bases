#! perl -w

my $VERSION = do { my @r = (q$Revision: 1.4 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

use Cwd;
use ExtUtils::testlib;
use Test::More tests => 25;

use strict;

BEGIN {
	use_ok('Tk::Wizard');
};

my $WAIT = 1;

ZERO:
  {
  my $wizard = new Tk::Wizard;
  isa_ok($wizard, "Tk::Wizard");
  is(1,$wizard->addPage( sub{ $wizard->blank_frame(-wait=>$WAIT) } ));
  $wizard->Show;
  MainLoop;
  ok('Pretest');
  }

ONE:
  {
  my $wizard = new Tk::Wizard( -title => "Test", );
  isa_ok($wizard, "Tk::Wizard");
  is(1,$wizard->addPage( sub{ $wizard->blank_frame(-wait=>$WAIT) } ), 'pre page');
  is(2, $wizard->addPage( sub{ page_splash ($wizard)} ), 'p1');
  is(3, $wizard->addPage (sub{page_finish($wizard)} ),'p2');
  $wizard->Show;
  MainLoop;
  isa_ok($wizard, "Tk::Wizard", "Wizard survived CloseWindowEventCycle");
  ok(1, 'end of ONE tests');
  }

TWO: {
	my $wizard = new Tk::Wizard( -title => "Test", );
	isa_ok($wizard, "Tk::Wizard");
	$wizard->configure(
		-preFinishButtonAction  => sub { ok(1, 'TWO preFinish'); },
		-finishButtonAction  => sub { ok(1, 'TWO finish');
                                              $wizard->destroy;
                                              1;
                                              },
	);
	isa_ok($wizard->cget(-finishButtonAction), "Tk::Callback");
	is(1, $wizard->addPage( sub{ page_splash ($wizard)} ), "TWO page one");
	is(2, $wizard->addPage (sub{page_finish($wizard)} ), "TWO page two");
	$wizard->Show;
	MainLoop;
	ok(1,'Done TWO');
}

THREE:
  {
  my $wizard = new Tk::Wizard( -title => "Test", );
  isa_ok($wizard, "Tk::Wizard");
  $wizard->configure(
                     -preFinishButtonAction  => sub { ok(1, 'THREE preFinish'); },
                     -finishButtonAction  => sub { ok(1, 'THREE finish'); },
                    );
  is(1, $wizard->addPage( sub{ page_splash ($wizard)} ), 'THREE addPage 1');
  is(2, $wizard->addPage (sub{page_finish($wizard)} ), 'THREE addPage 2');
  $wizard->Show;
  MainLoop;
  isa_ok($wizard, "Tk::Wizard", "Wizard survived CloseWindowEventCycle");
  ok(1, 'end of THREE block');
  } # end of THREE block
pass;
exit;

sub page_splash { my $wizard = shift;
	my $frame = $wizard->blank_frame(-wait=>$WAIT);
	# $frame->after($WAIT,sub{$wizard->forward});
	return $frame;
}

sub page_finish { my $wizard = shift;
	my ($frame,@pl) = $wizard->blank_frame(
		-wait=>$WAIT,
		-title=>"Wizard Test 'pb' Complete",
		-text=> "Thanks for running this test.",
	);
	#$frame->after($WAIT,sub{$wizard->forward});
	return $frame;
}

__END__

