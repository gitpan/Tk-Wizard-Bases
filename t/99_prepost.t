use ExtUtils::testlib;
use Test::More tests => 19;

BEGIN {
	use lib '../lib';
	use_ok('Tk::Wizard' => 1.945 )
};

my $Wait = 1000;

foreach my $style (qw[ top 95 ]){
	my $wizard = new Tk::Wizard(
		-debug	=> undef,
		-style => $style,
	);

	$wizard->configure(
			-preNextButtonAction => sub { &preNextButtonAction($wizard) },
			-postNextButtonAction => sub { &postNextButtonAction($wizard) },
			-preFinishButtonAction => sub { &postNextButtonAction($wizard) },
			-finishButtonAction => sub { &postNextButtonAction($wizard) },
	);

	$wizard->addPage( sub {
		$wizard->blank_frame(
			-title	=> "page 1",
			-wait	=> $Wait,
		);}
	);
	$wizard->addPage( sub {
		$wizard->blank_frame(
			-title  => "page 2",
			-wait	=> $Wait,
			-width	=> 300,
		);}
	);
	$wizard->addPage( sub {
		$wizard->blank_frame(
			-title  => "page 3",
			-wait	=> $Wait,
			-width	=> 900,
		);}
	);
	$wizard->addPage( sub {
		$wizard->blank_frame(
			-title  => "page last",
			-wait	=> $Wait,
		);}
	);

	$wizard->Show;
	MainLoop;
}

sub preNextButtonAction { my $wizard = shift;
    $_ = $wizard->currentPage;
    push @out, "pre next button on page $_";
    print $out[$#out],"\n";
    pass;
    return 1;
}

sub postNextButtonAction { my $wizard = shift;
    $_ = $wizard->currentPage;
    push @out, "post next button on page $_";
    print $out[$#out],"\n";
    pass;
    return 1;
}


sub preFinishButtonAction { my $wizard = shift;
    $_ = $wizard->currentPage;
    push @out, "pre finish button on page $_";
    print $out[$#out],"\n";
    pass;
    return 1;
}

sub finishButtonAction { my $wizard = shift;
    $_ = $wizard->currentPage;
    push @out, "finish button on page $_";
    print $out[$#out],"\n";
    pass;
    return 1;
}
