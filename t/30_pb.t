#! perl -w

my $VERSION = do { my @r = (q$Revision: 1.4 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

use Cwd;
use ExtUtils::testlib;
use Test::More no_plan;

use strict;

BEGIN { use_ok('Tk::Wizard') };
BEGIN { use_ok('Tk::ProgressBar') };

our ($PB);	# Index number of page
our $bar;	# Progress bar

my $wizard = new Tk::Wizard(
	-title => "ProgressBar Test",
	-image_dir	=> 'lib/Tk/Wizard/images/',
	-imagepath => "./Wizard/images/wizard_blue.gif",
	-style	=> 'top',
	-topimagepath => "./Wizard/images/wizard_blue_top.gif",
);
isa_ok($wizard, "Tk::Wizard");
$wizard->configure(
	-postNextButtonAction => sub { &postNextButtonAction($wizard) },
	-preNextButtonAction => sub { &preNextButtonAction($wizard) },
	-finishButtonAction  => sub { ok(1);  $wizard->destroy;},
);
isa_ok($wizard->cget(-preNextButtonAction), "CODE");

is(1, $wizard->addPage( sub{ page_splash ($wizard)} ));
$PB = $wizard->addPage( sub{ pb($wizard) });
is(2, $PB);
is(3, $wizard->addPage (sub{page_finish($wizard)} ));
$wizard->Show;
MainLoop;
ok(1);
exit;

sub page_splash { my $wizard = shift;
	my $frame = $wizard->blank_frame(-title=>"Welcome to the Wizard Test 'pb'",
	-text=>
		"This script tests and hopefully demonstrates the 'postNextButtonAction' feature.\n\n"
		."When you click Next, a Tk::ProgressBar widget should slowly be udpated."
	);
	$frame->after(100,sub{$wizard->forward});
	return $frame;
}

sub page_finish { my $wizard = shift;
	my ($frame,@pl) = $wizard->blank_frame(-title=>"Wizard Test 'pb' Complete",
		-text=> "Thanks for running this test.",
	);
	$frame->after(100,sub{$wizard->forward});
	return $frame;
}

sub pb { my $wizard = shift;
	my $frame = $wizard->blank_frame(
		-title=>"postNextButtonAction Test",
		-subtitle=>"Updating a progress bar in real-time",
		-text=>"The bar should fill, thanks to calling the 'update' method upon the Wizard, "
		."and the Next button should only become available when the job is done."
	);
         # $frame->configure(-bg => 'magenta'); # for debugging
	$bar = $frame->ProgressBar(
                                   -colors=>[0=>'yellow'],
                                   -borderwidth => 2, -relief => 'sunken',
                                   -from => 0,	-to => 10,
                                   -height => 15,
	)->pack( -padx => 10, -pady => 10, -side => 'top', -fill => 'x', -expand => 1 );
	return $frame;
}

sub preNextButtonAction { my $wizard = shift;

}

sub postNextButtonAction { my $wizard = shift;
	$_ = $wizard->currentPage;
	if (/^$PB$/){
		$wizard->{nextButton}->configure(-state=>"disable");
		$wizard->update;
		for my $i (0..$bar->cget(-to)){
			sleep 1;
			$bar->value($i);
			$bar->update;
		}
		$wizard->{nextButton}->configure(-state=>"normal");
		$wizard->{nextButton}->after(100,sub{$wizard->forward});
	}
	return 1;
}


__END__

