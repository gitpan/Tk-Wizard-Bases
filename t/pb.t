#! perl -w
our $VERSION = 0.1;	# 29 November 2002 14:39 CET

use strict;
use Cwd;

print "1..5\n";

use Tk::Wizard;
use Tk::ProgressBar;
print "ok 1\n";


our ($PB);	# Index number of page
our $bar;	# Progress bar

my $wizard = new Tk::Wizard(
	-title => "ProgressBar Test",
	-imagepath => "./Wizard/images/wizard_blue.gif",
	-style	=> 'top',
	-topimagepath => "./Wizard/images/wizard_blue_top.gif",
);
print ref $wizard eq "Tk::Wizard"? "ok 2\n" : "not ok 2\n";
$wizard->configure(
	-postNextButtonAction => sub { &postNextButtonAction($wizard) },
	-preNextButtonAction => sub { &preNextButtonAction($wizard) },
	-finishButtonAction  => sub { print "ok 4\n";  $wizard->destroy;},
);
print ref $wizard->cget(-preNextButtonAction) eq "CODE"? "ok 3\n":"not ok 3\n";

$wizard->addPage( sub{ page_splash ($wizard)} );
$PB = $wizard->addPage( sub{ pb($wizard) });
$wizard->addPage (sub{page_finish($wizard)} );
$wizard->Show;
MainLoop;
print "ok 5\n";

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
	$bar = $frame->ProgressBar(
		-colors=>[0=>'yellow'],
		-borderwidth => 2, -relief => 'sunken',
		-from => 0,	-to => 10,
	)->pack( -padx => 10, -pady => 10, -side => 'top', -fill => 'both', -expand => 1 )->pack;
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
