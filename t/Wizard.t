#! perl -w

our $VERSION = 0.4;	# 28 November 2002 23:30 CET

use strict;
use Cwd;

use vars qw/$GET_DIR $user_chosen_dir $SPLASH/;

print "1..9\n";

use lib "../..";
use Tk::Wizard 1.06;

print "ok 1\n";
my $test = 1;


#
# Instantiate Wizard
#
my $looped = 0;
foreach my $style ('top',''){
	my $wizard = new Tk::Wizard(
		-title => "Test v$VERSION For Wizard $Tk::Wizard::VERSION",
		-style	=> $style,
	);

	++$test;
	print ref $wizard eq "Tk::Wizard"? "ok $test ### Loop start\n" : "not ok $test\n";

	$wizard->configure(
		-preNextButtonAction => sub { &preNextButtonAction($wizard) },
		-finishButtonAction  => sub { ++$test; print "ok $test\n";  },
	);


	++$test;
	print ref $wizard->cget(-preNextButtonAction) eq "CODE"? "ok $test\n":"not ok $test\n";

	#
	# Create pages
	#

	$SPLASH       	= $wizard->addPage( sub{ page_splash ($wizard,$looped)} );
	++$test;
	print $SPLASH==1? "ok $test\n":"not ok $test\n";


	$wizard->addPage( sub{ page_one($wizard) });
	$wizard->addPage( sub{ page_two($wizard) });
	$wizard->addPage( sub{ page_text_textbox1($wizard) });
	$wizard->addPage( sub{ page_text_textbox2($wizard) });
	my ($C1,$C2,$C3) = (undef,"TWooo",3);
	$wizard->addMultipleChoicePage(-title=>'Multi',-subtitle=>'Multiple Choice Page',-text=>"Something here too?",
		-choices=> [
			{-variable=>\$C1,-title=>"Option number one",-subtitle=>"This is the first of three options, each of which may take a value.",-value=>'1',},
			{-variable=>\$C2,-title=>"The Second option is here",-subtitle=>"The Lumberjack Song, German version",-value=>'two',-checked=>1,},
			{-variable=>\$C3,-title=>"And no subitle either",-value=>'two',},
		],
	);


	$GET_DIR 	= $wizard->addDirSelectPage (
		-nowarnings => "1",
		-variable => \$user_chosen_dir,
		);
	++$test;
	print $GET_DIR==7? "ok $test\n":"not ok $test # $GET_DIR\n";

	my $p = $wizard->addPage( sub {
		return $wizard->blank_frame(
			-title=>"Finished",
			-subtitle => "Please press Finish to leave the Wizard.",
			-text => "By the way, you selected the directory $user_chosen_dir.\n\n"
			."If you saw some error messages, they came from Tk::DirTree, and show "
			."that some of your drives are inacessible - perhaps a CD-ROM drive without "
			."media.  Such warnings can be turned off - please see the documentation for details."
		);
	});
	++$test;
	print $p? "ok $test\n":"not ok $test\n";

	++$test;
	print ref $wizard->parent eq "Tk::Wizard"? "ok $test\n":"not ok $test\n";

	$wizard->Show();
	MainLoop;
	++$test;
	print "ok $test\n";
}

exit;


sub page_splash { my ($wizard,$looped) = (shift,shift);
	my ($frame,@pl) = $wizard->blank_frame(
		-title	=> ($looped==0? "Welcome to the Wizard" : "Testing the Old Style"),
		-subtitle=>"It's just a test",
		-text=>
		"This Wizard is a simple test of the Wizard, and nothing more.\n\nNo software will be installed, but you'll hopefully see a licence agreement page, and a directory listing page."
	);
	return $frame;
}


sub page_one { my $wizard = shift;
	my $frame = $wizard->blank_frame(
		-title=>"-title here",
		-subtitle=>'The text found in the -subtitle paramter appears here on the screen; quite a long string I trust: and sadly ugly still',
		-text=>"-text goes here.\n\nTk::Wizard is but a baby, and needs your help to grow into a happy, healthy, well-adjusted widget. Sadly, I've only been using Tk::* for a couple of weeks, and all this packing takes a bit of getting used to. And I'm also working to a deadline on the project which bore this Wizard, so please excuse some coding which is currently rather slip-shod, but which be tightened in the future."
	);
	return $frame;
}

sub page_two { my $wizard = shift;
	my $frame = $wizard->blank_frame(
		-title=>"The Title",
		-text=>"A page without a -subtitle."
	);
	return $frame;
}

sub page_bye { my $wizard = shift;
	my $frame = $wizard->blank_frame(
		-title=>"Bye!",
		-text=>"Thanks for testing!"
	);
	return $frame;
}

sub page_text_textbox1 { my $wizard = shift;
	my $text = "THis is in a box";
	my $frame = $wizard->text_frame(
		-title=>"1: Text from literal",
		-boxedtext => \$text,
	);
	return $frame;
}
sub page_text_textbox2 { my $wizard = shift;
	my $frame = $wizard->text_frame(
		-title=>"2: Text from filename",
		-boxedtext => 'perl_licence_blab.txt',
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
