package Tk::Wizard::Installer;

$Tk::Wizard::Installer::VERSION = do { my @r = (q$Revision: 1.932 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
# 24 April 2006

=head1 NAME

Tk::Wizard::Installer - building-blocks for a software install wizard

	use Tk::Wizard::Installer 1.932;
	my $wizard = new Tk::Wizard::Installer( -title => "Installer Test", );
	$wizard->addDownloadPage(
		-wait   => undef,
		#-on_error => sub { ... },
		-no_retry => 1,
		-files  => {
			'http://www.cpan.org/'      => './cpan_index1.html',
			'http://www.cpan.org/'      => './cpan_index2.html',
			'http://www.leegoddard.net' => './author.html',
		},
	);
	$wizard->addPage( sub {
		return $wizard->blank_frame(
			-title=>"Finished",
			-subtitle => "Please press Finish to leave the Wizard.",
			-text => ""
		);
	});
	$wizard->Show;
	MainLoop;

=cut

use strict;
use Carp;
use warnings;
no warnings 'redefine';
use Cwd;
use File::Path;
use File::Copy;
use File::Spec;
use Tk::Wizard 1.943;
use Tk::ProgressBar;
use Tk::LabFrame;
require Tk::ErrorDialog;
require Exporter;
use vars qw/@ISA @EXPORT/;
@ISA = "Tk::Wizard";
@EXPORT = ("MainLoop");

# See INTERNATIONALISATION

my %LABELS = (
	# Buttons
	BACK => "< Back",	NEXT => "Next >",
	FINISH => "Finish",	CANCEL => "Cancel",
	HELP => "Help", OK => "OK",

	# licence agreement
	LICENCE_ALERT_TITLE	=> "Licence Condition",
	LICENCE_OPTION_NO	=> "I do not accept the terms of the licence agreement",
	LICENCE_OPTION_YES	=> "I accept the terms of the licence agreement",
	LICENCE_IGNORED		=> "You must read and agree to the licence before you can use this software.\n\nIf you do not agree to the terms of the licence, you must remove the software from your machine.",
	LICENCE_DISAGREED	=> "You must read and agree to the licence before you can use this software.\n\nAs you indicated that you do not agree to the terms of the licence, please remove the software from your machine.\n\nSetup will now exit.",

	# FileList
	# - supplied as args: see POD for those sections
);

=head1 DESCRIPTION

This module makes the first moves towards a C<Tk::Wizard> extension
to automate software installation, primarily for end-users, in the manner
of I<Install Sheild>.

If you are looking for a freeware software installer that is not
dependant upon Perl, try I<Inno Setup> - C<http://www.jrsoftware.org/>. It's
so good, even Microsoft have been caught using it.

=head1 DEPENDENCIES

	Tk::Wizard;
	Tk::ProgressBar;
	Tk::LabFrame;

=head1 DETAILS

C<Tk::Wizard::Installer> supports all the methods and means of L<Tk::Wizard|Tk::Wizard>
plus those listed in the remainder of this document.

=head2 METHOD addLicencePage

	$wizard->addLicencePage ( -filepath => $path_to_licence_text )

Adds a page (C<Tk::Frame>) that contains a scroll text box of a licence text file
specifed in the C<-filepath> argument. Presents the user with two
options: accept and continue, or don't accept and quit. The user
I<cannot> progress until the former option has been chosen. The
choice is entered into the object field C<licence_agree>, which you
can test as the I<Next> button is pressed, either using your own
function or with the Wizard's C<callback_licence_agreement> function.

You could supply a copy of the licence that comes with Perl.

See L<CALLBACK callback_licence_agreement> and L<METHOD page_licence_agreement>.

=cut

sub addLicencePage { my ($self,$args) = (shift, {@_});
	die "No -filepath argument present" if not $args->{-filepath};
	$self->addPage( sub { $self->page_licence_agreement($args->{-filepath} )  } );
}



#
# PRIVATE METHOD page_licence_agreement
#
#	my $COPYRIGHT_PAGE = $wizard->addPage( sub{ Tk::Wizard::page_licence_agreement ($wizard,$LICENCE_FILE)} );
#
# Accepts a C<TK::Wizard> object and the path to a text file
# containing the licence.
#
# Returns a C<Tk::Wizard> page entitled "End-user Licence Agreement",
# a scroll-box of the licence text, and an "Agree" and "Disagree"
# option. If the user agrees, the caller's package's global (yuck)
# C<$LICENCE_AGREE> is set to a Boolean true value.
#
# If the licence file cannot be read, this routine will call C<die $!>.
#
# See also L<CALLBACK callback_licence_agreement>.
#
sub page_licence_agreement { my ($self,$licence_file) = (shift,shift);
	local *IN;
	my $text;
	my $padx = $self->cget(-style) eq 'top'? 30 : 5;
	$self->{licence_agree} = undef;
	open IN,$licence_file or croak "Could not read licence: $licence_file; $!";
	read IN,$text,-s IN;
	close IN;
	my ($frame,@pl) = $self->blank_frame(
		-title	 =>"End-user Licence Agreement",
		-subtitle=>"Please read the following licence agreement carefully.",
	);
	my $t = $frame->Scrolled(
		qw/ROText -relief sunken -borderwidth 2 -font SMALL_FONT -width 10 -setgrid true
		-height 9 -scrollbars e -wrap word/
	);

	$t->insert('0.0', $text);
	$t->configure(-state => "disabled");
	$t->pack(qw/-expand 1 -fill both -padx 10 -pady 10/);
	my %opts1 = (
		-font => $self->{defaultFont},
		-text     => $LABELS{LICENCE_OPTION_YES},
		-variable => \${$self->{licence_agree}},
		-relief   => 'flat',
		-value    => 1,
		-anchor	=> 'w',
	);
        # Setting -background to undef causes core dump deep inside Tk!
        $opts1{-background} = $self->cget("-background") if $self->cget("-background");

	if ($^O !~ /(win32|cygwin)/i){
		$opts1{-underline} = 2;
	}
	$frame->Radiobutton( %opts1 )->pack(-padx=>$padx, -anchor=>'w',);
	my %opts2 = (
		-font => $self->{defaultFont},
		-text     => $LABELS{LICENCE_OPTION_NO},
		-variable => \${$self->{licence_agree}},
		-relief   => 'flat',
		-value    => 0,
		-anchor	=> 'w',
	);
        # Setting -background to undef causes core dump deep inside Tk!
        $opts2{-background} = $self->cget("-background") if $self->cget("-background");
	if ($^O !~ /(win32|cygwin)/i){
		$opts2{-underline} = 5;
	}
    $frame->Radiobutton(%opts2)->pack(-padx=>$padx, -anchor=>'w',);
	return $frame;
}


=head2 CALLBACK callback_licence_agreement

Intended to be used with an action-event handler like C<-preNextButtonAction>,
this routine check that the object field C<licence_agree>
is a Boolean true value. If that operand is not set, it warns
the user to read the licence; if that operand is set to a
Boolean false value, a message box says goodbye and quits the
program.

=cut

sub callback_licence_agreement { my $self = shift;
	if (not defined ${$self->{licence_agree}}){
		my $button = $self->parent->messageBox('-icon'=>'info',-type=>'ok',
		-title => $LABELS{LICENCE_ALERT_TITLE},
		-message => $LABELS{LICENCE_IGNORED});
		return 0;
	}
	elsif (not ${$self->{licence_agree}}){
		my $button = $self->parent->messageBox('-icon'=>'warning', -type=>'ok',-title=>$LABELS{LICENCE_ALERT_TITLE},
		-message => $LABELS{LICENCE_DISAGREED});
		exit;
	}
	return 1;
}


=head2 METHOD addDirSelectPage

See L<TK::Wizard/METHOD adddirSelectPage>.

=head2 METHOD addFileListPage

	$wizard->addFileListPage ( name1=>value1 ... nameN=>valueN )

Adds a page (C<Tk::Frame>) that a contains a progress bar
(C<Tk::ProgressBar>) which is updated as a supplied list of files
is copied or mvoed from one location to another.

The I<Next> and I<Back> buttons of the Wizard are disabled whilst
the process takes place.

The two arguments (below) C<-to> and C<-from> should be references
to arrays (or anonymous arrays), where entries in the former are
moved or copied to the locations specified to the equivalent
entries in the latter, renaming and path creation occuring as needed:

	-copy => 1,
	-to   => [
		'/html/index.html',
		'/html/imgs/index.gif',
		'/html/oldname.html'
	],
	-from => [
		'/docs/',
		'/docs/imgs/',
		'/html/newname_for_oldname.html'
	],

The above example
copies C<index.html> to C</docs/index.html>, C<index.gif> is copied to
become C</docs/imgs/index.gif>, and C<oldname.html> is moved to the C<html>
directory and given the new name, C<newname_for_oldname.html>.

Arguments:

=over 4

=item -title

=item -subtitle

=item -text

See C<Tk::Wizard/METHOD blank_frame>.

=item -copy

=item -move

Setting one or the other will determine whether files are copied (without deletion of originals)
or moved (with deletion of originals). The default action is the former.

=item -from

Rerence to an array of locations to copy/move from

=item -to

Rerence to an array of locations to move/copy to

=item -delay

Delay (in mS) before copying begins (see L<Tk::After>). Default is 1000.

=item -wait

Prevents display of the next Wizard page once the job is done.

=item -bar

A list of properties to pass to the C<Tk::ProgessBar> object created and used
in this routine. Assumes reasonable defaults.

=item -label_frame_title

Text for the label frame (C<Tk::LabFrame> object) which contains our moving parts.
Defaults to C<Copying Files>.

=item -label_preparing

Text for label displayed whilst counting files to be copied.
Defaults to C<Preparing...>.

=item -label_from

The text of the label prepended to the name of the directory being copied.
Defaults to C<From:>.

=item -label_file

The text of the labe prepended to the name of the file being copied.
Defaults to C<Copying:>.

=item -on_error

A code reference to handle errors, which are detailed in the anonymous hash C<-failed>,
where names are filenames and values are the error messages.
If not supplied, calls L<DIALOGUE pre_install_files_quit>.

=back

=cut

# Internally (as private as it gets in Perl):
#
# =item -bar
#
# Confusingly, a progressBar object to update
#
# =item -labelDir
#
# Label object to update
#
# =item -labelFile
#
# Label object to update
#
sub addFileListPage { my ($self,$args) = (shift, {@_});
	$self->addPage( sub { $self->page_fileList( $args )  } );
}


# See instasll_files and addFileListPage
sub page_fileList { my ($self,$args) = (shift,shift);
	croak "Arguments should be supplied as a hash ref" if not ref $args or ref $args ne "HASH";
	croak "-from and -to are required" if not $args->{-from} or not $args->{-to};
	croak "-from and -to are different lengths" if $#{$args->{-from}} != $#{$args->{-to}};
	croak "Nothing to do! -from and -to empty" if $#{ $args->{-from}}==-1 or $#{ $args->{-to}}==-1;
	my $frame = $self->blank_frame(
		-title => $args->{-title} || "Copying Files" ,
		-subtitle => $args->{-subtitle} || "Please wait whilst Setup copies files to your computer.",
		-text => $args->{-text} || "\n"
	);

	my %bar; # progress bar args
	if ($args->{-bar}){
		%bar = @{$args->{-bar}};
		# insert error checking here...
	}
	$bar{-gap}	  = 0 unless defined $bar{-gap};
	$bar{-blocks} = 0 unless defined $bar{-blocks};
	$bar{-colors} = [0=>'blue'] unless $bar{-colors};
	$bar{-borderwidth} = 2 unless $bar{-borderwidth};
	$bar{-relief} = 'sunken' unless $bar{-relief};
	$bar{-from}   = 0 unless $bar{-from};
	$bar{-to}	  = 100 unless $bar{-to};

	my $f = $frame->LabFrame(-label => $args->{-label_frame_title} || "Copying files", -labelside => "acrosstop");
	$args->{-labelFile} = $f->Label(qw//)->pack(qw/-padx 16 -side top -anchor w/);
	$args->{-labelDir}  = $f->Label(qw//)->pack(qw/-padx 16 -side top -anchor w/);
	$self->{-bar} = $f->ProgressBar( %bar )->pack(
		qw/ -padx 20 -pady 10 -side top -anchor w -fill both -expand 1 /
	);
	$f->pack(qw/-fill x -padx 30/);

	$self->{nextButton}->configure(-state=>"disable");
	$self->{backButton}->configure(-state=>"disable");

	$self->{-bar}->after ( $args->{-delay} || 1000, sub {
		my $todo = $self->pre_install_files($args);
		warn "# Configure bar to $todo\n" if $self->{-debug};
		$self->{-bar}->configure(-to => $todo );
		$self->install_files($args);
		$self->{nextButton}->configure(-state=>"normal");
		$self->{backButton}->configure(-state=>"normal");
		#$self->{nextButton}->invoke unless $args->{-wait};

		if ($args->{-wait}){
			Tk::Wizard::fix_wait( \$args->{-wait} );
#			$frame->after($args->{-wait},sub{$self->forward});
			$frame->after(
				$args->{-wait},sub {
					$self->{nextButton}->configure(-state=>'normal');
					$self->{nextButton}->invoke;
				}
			);
		}

	});
	return $frame;
}


# Pre-parse, counting files and expanding directories if necessary
# Return total number of files to process
# Puts any failures into %{$self->{-failed}}
sub pre_install_files { my ($self,$args) = (shift,shift);
	croak "Arguments should be supplied as a hash ref" if not ref $args or ref $args ne "HASH";
	croak "-from and -to are different lengths" if $#{$args->{-from}} != $#{$args->{-from}};
	my $total = 0;
	my $i=-1;
	$args->{-labelDir}->configure(-text => $args->{-label_preparing} || "Preparing..." ) ;
	$args->{-labelDir}->update;
	$args->{-labelFile}->configure(-text => "") ;
	$args->{-labelDir}->update;
	$self->{-failed} = {};
	my @to   = @{ $args->{-to  } };
	my @from = @{ $args->{-from} };

	foreach (@to){
		$i++;
		# Directories:
		if (-d $from[$i]){
			local *DIR;
			my $orig_dir = cwd;
			chdir $from[$i] or die "Weird dir error";
			opendir DIR,"." or die "Weird dir error";
			foreach ( grep {!/^\.{1,2}$/} readdir DIR ){
				push @from, $from[$i]."/".$_;
				push @to,   $to[$i]."/".$_;
			}
			close DIR;
			chdir $orig_dir;
			next;
		}
		# Files:
		elsif (-r $from[$i]){
			$total++
		}

		else {
			warn "Could not read file $from[$i]" if $self->{-debug};
			$self->{-failed}->{$from[$i]} = "Could not read file";
			$args->{-from}->[$i] = undef;
		}
	}

	if (scalar keys %{$self->{-failed}}>0){
		warn "# Failed ".(scalar keys %{$self->{-failed}}) if $self->{-debug};
		if ( ref $args->{-on_error} eq 'CODE'){
			warn "# Calling -on_error handler." if $self->{-debug};
			&{ $args->{-on_error} }
		} else { # if ($args->{-on_error}) {
			warn "# Calling self/pre_install_files_quit." if $self->{-debug};
			$self->pre_install_files_quit( scalar keys %{$self->{-failed}} );
		}
	}

	return $total; # why was it total+1?
}


# See page_fileList
sub install_files { my ($self,$args) = (shift,shift);
	croak "Arguments should be supplied as a hash ref" if not ref $args or ref $args ne "HASH";
	croak "-from and -to are different lengths" if $#{$args->{-from}} != $#{$args->{-from}};
	$args->{-label_from} = "From: " if not $args->{-label_from};
	$args->{-label_file} = "Copying: " if not $args->{-label_file};
	my $total = 0;
	my $i=-1;
	foreach (@{ $args->{-to} }){
		$i++;
		# Directories:
		if (-d @{$args->{-from}}[$i]){
			local *DIR;
			my $orig_dir = cwd;
			chdir @{$args->{-from}}[$i] or die "Weird dir error";
			opendir DIR,".";
			foreach ( grep {!/^\.{1,2}$/} readdir DIR ){
				push @{$args->{-from}}, @{$args->{-from}}[$i]."/".$_;
				push @{$args->{-to  }}, @{$args->{-to  }}[$i]."/".$_;
			}
			close DIR;
			chdir $orig_dir;
			next;
		}
		# Files:
		elsif (-r @{$args->{-from}}[$i]){
			# update the display
			my ($fv,$fd,$ff) = File::Spec->splitpath( @{$args->{-from}}[$i] );
			my ($tv,$td,$tf) = File::Spec->splitpath( @{$args->{-to}}[$i] );
			if ($args->{-labelDir} ne $args->{-label_from}."$fv$fd"){
				$args->{-labelDir}->configure(-text => $args->{-label_from}."$fv$fd") ;
				$args->{-labelDir}->update;
			}
			$args->{-labelFile}->configure(-text => $args->{-label_file}.$ff);
			$args->{-labelFile}->update;
			$self->{-bar}->value( $self->{-bar}->value +1 );
			warn "# Updating bar to ".$self->{-bar}->value."\n" if $self->{-debug};
			$self->{-bar}->update;

			# Make the path, if needs be
			my $d = "$tv/$td";
			$d =~ s/[\\\/]+/\//g;
			if (!-d "$d"){
				mkpath $d or croak "Could not make path $d : $!";
			}

			# Do the move/copy
			if ($args->{-move}){
				if (not move( @{$args->{-from}}[$i], @{$args->{-to}}[$i] )){
					$self->{-failed}->{@{$args->{-from}}[$i]} = "Could not read file";
					@{$args->{-from}}[$i] = undef;
				}
			} else {
				if (not copy(@{$args->{-from}}[$i], @{$args->{-to}}[$i] )){
					$self->{-failed}->{@{$args->{-from}}[$i]} = "Could not read file";
					@{$args->{-from}}[$i] = undef;
				}
			}
		}

		else {
			$self->{-failed}->{@{$args->{-from}}[$i]} = "Could not read file";
			@{$args->{-from}}[$i] = undef;
		}
	}

	if (scalar keys %{$self->{-failed}}>0){
		warn "# Failed ".(scalar keys %{$self->{-failed}}) if $self->{-debug};
		if ( ref $args->{-on_error} eq 'CODE'){
			warn "# Calling -on_error handler." if $self->{-debug};
			&{ $args->{-on_error} }
		} else { # ($args->{-on_error}) {
			warn "# Calling pre_install_files_quit." if $self->{-debug};
			$self->pre_install_files_quit( scalar keys %{$self->{-failed}} );
		}
	}



	return $total; # why was it total + 1?
}


=head2 DIALOUGE METHOD DIALOGUE_really_quit

Called when the user tries to quit.
As opposed to the base C<Wizard>'s dialouge of the same name,
this dialogue refers to "the Instllaer", rather than "the Wizard".

=cut

sub Tk::Wizard::DIALOGUE_really_quit { my $self = shift;
	return 0 if $self->{nextButton}->cget(-text) eq $LABELS{FINISH};
	warn "# Installer DIALOGUE_really_quit  ...\n" if $self->{-debug};
	unless ($self->{really_quit}){
		my $button = $self->parent->messageBox(
			-icon		=> 'question',
			-type 		=> 'yesno',
			-default	=> 'no',
			-title 		=> 'Quit The Installation?',
			-message	=> "The Installer has not finished running.\n\nIf you quit now, the installation will be incomplete.\n\nDo you really wish to quit?"
		);
		$self->{really_quit} = lc $button eq 'yes'? 1:0;
	}
	if ( $self->{really_quit} ){
		warn "# Quitting\n" if $self->{-debug};
		$self->{cancelButton}->configure(-state=>'normal');
		$self->{cancelButton}->invoke;
	} else {
		warn "# Ok, continuing\n" if $self->{-debug};
	}
	return !$self->{really_quit};
}


=head2 DIALOUGE METHOD pre_install_files_quit

Asks if the user wishes to continue after file copy errors.

=cut

sub pre_install_files_quit { my ($self, $failed) = (shift, shift);
	warn "# pre_install_files_quit ...\n" if $self->{-debug};
	my $button = $self->parent->messageBox(
		-icon => 'error',
		-type => 'yesno',
		-default => 'no',
		-title => 'Abort Installation?',
		-message => "Failed to copy $failed file"
		.($failed!=1?"s":"")
		.".\n\n"
		."Do you wish to continue anyway?",
	);
	if (lc $button eq 'no'){
		warn "Won't continue....\n" if $self->{-debug};
		$self->{cancelButton}->configure(-state=>'normal');
		$self->{cancelButton}->invoke;
	} else {
		warn "Will continue.\n" if $self->{-debug};
	}
}


=head2 METHOD addDownloadPage

	$wizard->addDownloadPage ( name1=>value1 ... nameN=>valueN )

Adds a page (C<Tk::Frame>) that will attempt to download specified
files to specified locations, updating two progress bars in the
process.

If a file cannot be downloaded, the user will be prompted to try
again. If the user sooner or later wishes to carry on even though
a file has not downloaded, the the calling C<Wizard>'s C<-failed>
slot is filled with the URIs of the files that could not be downloaded,
and the supplied C<-on_error> argument comes into play - see below.
If no C<-on_error> paramter is provided, the Wizard will continue.

The I<Next> and I<Back> buttons of the Wizard are disabled whilst
the download process takes place.

=over 4

=item -files

A refernece to a hash, where keys are URIs and
values are local locations to place the contents of those URIs.

=item -wait

If supplied, the frame will remain on the screen when the download
is complete - default is to automate a click on the C<next> button
once the downloads are completed without errors.

=item -bar

A list of properties to pass to the C<Tk::ProgessBar> object created and used
in this routine. Assumes reasonable defaults.

=item -no_retry

If set to a true value, will prevent the I<Try again?> dialogue.

=item -on_error

If a file cannot be downloaded and the user chooses not to keep trying,
then this paramter comes into operation. If it is a reference, then it
is assumed to be a code reference to execute; oftherwise a dialgoue box
asks the user if they really wish to quit. If they do, then the
C<CloseWindowEventCycle> (see L<Tk::Wizard/CloseWindowEventCycle>) - the
default result of which is yet another confirmation of closure....

If no C<-on_error> paramter is provided, the Wizard will continue even
if it cannot download the requested data.

=item -done_text

Text to display when complete. Default: I<complete>.

= back

Would it be useful to impliment globbing for FTP URIs?

=cut


sub addDownloadPage { my ($self,$args) = (shift, {@_});
	$self->addPage( sub { $self->page_download( $args )  } );
}


# See instasll_files and addFileListPage
sub page_download{ my ($self,$args) = (shift,shift);
	croak "Arguments should be supplied as a hash ref" if not ref $args or ref $args ne "HASH";
	croak "-files is required" if not $args->{-files};
	croak "-files should be a hash of uri => filepath pairs" if ref $args->{-files} ne 'HASH';
	my @failed;
	my $frame = $self->blank_frame(
		-title => $args->{-title} || "Downloading Files" ,
		-subtitle => $args->{-subtitle} || "Please wait whilst Setup downloads files to your computer.",
		-text => $args->{-text} || "\n"
	);

	my %bar; # progress bar args
	if (defined $args->{-bar}){
		%bar = @{$args->{-bar}};
		# insert error checking here...
	}
	$bar{-gap}	  = 0 unless defined $bar{-gap};
	$bar{-blocks} = 0 unless defined $bar{-blocks};
	$bar{-colors} = [0=>'blue'] unless $bar{-colors};
	$bar{-borderwidth} = 2 unless $bar{-borderwidth};
	$bar{-relief} = 'sunken' unless $bar{-relief};
	$bar{-from}   = 0 unless $bar{-from};
	$bar{-to}	  = 100 unless $bar{-to};

	my $all = $frame->LabFrame(
		-label => $args->{-label_all_files} || "Over-all Progress",
		-labelside => "acrosstop"
	);
	$self->{-bar} = $all->ProgressBar( %bar )->pack(
		qw/ -padx 20 -pady 10 -side top -anchor w -fill both -expand 1 /
	);
	$all->pack(qw/-fill x -padx 30/);

	$args->{file_label} = $frame->LabFrame(
		-label => $args->{-label_this_file} || "This FIle",
		-labelside => "acrosstop"
	);
	$args->{-file_bar} = $args->{file_label}->ProgressBar( %bar )->pack(
		qw/ -padx 20 -pady 10 -side top -anchor w -fill both -expand 1 /
	);
	$args->{file_label}->pack(qw/-fill x -padx 30/);

	$self->{nextButton}->configure(-state=>"disable");
	$self->{backButton}->configure(-state=>"disable");

	$self->{-bar}->after ( $args->{-delay} || 10, sub {
	    # $self->{nextButton}->configure(-state=>"disable");
		# $self->{backButton}->configure(-state=>"disable");

		require LWP::UserAgent;
		require HTTP::Request;

		while (scalar keys %{$args->{-files}}>0){

			$args->{file_label}->configure(-label=>'Preparing to download...');
			$args->{file_label}->update;
			$self->{-bar}->value(0);
			$self->{-bar}->configure( -to => scalar keys %{$args->{-files}} );

			foreach my $uri (keys %{$args->{-files}} ){
				warn "# Try $args->{-files}->{$uri}\n" if $self->{-debug};
				my ($uri_msg) = $uri =~ m/^\w+:\/{2,}[^\/]+(.*?)\/?$/;
				$args->{file_label}->configure(-label=> $uri_msg || "Current File");
				$args->{file_label}->update;
				if ($self->read_uri (
					bar		=> $args->{-file_bar},
					uri		=> $uri,
					target	=> $args->{-files}->{$uri},
				)){
					delete $args->{-files}->{$uri};
				}
				$self->{-bar}->value( $self->{-bar}->value +1 );
				$self->{-bar}->update;
				$args->{-file_bar}->configure(-to => 0);
				$args->{-file_bar}->value(0);
				$args->{-file_bar}->update;
			}

			if (scalar keys %{$args->{-files}}>0){
				warn "# Files left: ",(scalar keys %{$args->{-files}}),"\n" if $self->{-debug};
				if ($args->{-no_retry} or not $self->download_again(scalar keys %{$args->{-files}})){
					warn "# Not trying again.\n" if $self->{-debug};
					$self->{-failed} = $args->{-files};
					$args->{-files} = {};
				}
			}
		}

		if (scalar keys %{$self->{-failed}}>0 and $args->{-on_error}){
			warn "# Failed." if $self->{-debug};
			if ( ref $args->{-on_error} eq 'CODE'){
				warn "# Calling -on_error handler." if $self->{-debug};
				&{ $args->{-on_error} }
			} elsif ($args->{-on_error}) {
				warn "# Calling self/download_quit." if $self->{-debug};
				$self->download_quit( scalar keys %{$self->{-failed}} );
			}
		}
		else {
			warn "# Failures: ",scalar keys %{$self->{-failed}},"\n" if $self->{-debug};
			foreach (keys %{$self->{-failed}}){
				warn "# \t$_\n" if $self->{-debug};
			}
			$self->{-failed} = 0;
		}
		$self->{-bar}->packForget;
		$args->{-file_bar}->packForget;
		$args->{file_label}->packForget;
		$all->packForget;

		$frame->Label(
			-text => $args->{-done_text} || "Finished",
		)->pack(-fill => "both", -expand=>1);

		# $self->{backButton}->configure(-state=>"normal");
		$self->{nextButton}->configure(-state=>"normal");
		if ($args->{-wait}){
			Tk::Wizard::fix_wait( \$args->{-wait} );
#			$frame->after($args->{-wait},sub{$self->forward});
			$frame->after(
				$args->{-wait},sub {
					$self->{nextButton}->configure(-state=>'normal');
					$self->{nextButton}->invoke;
				}
			);
		}
	});

	return $frame;
}





# c/o PPM.pm
sub read_uri { my ($self,$args) = (shift,{@_});
    carp "Require uri param" unless defined $args->{uri};
    carp "Require target param" unless defined $args->{target};
    my ($proxy_user, $proxy_pass);
	($self->{response}, $self->{bytes_transferred},$self->{errstr}) = (undef, 0, undef);

    my $ua = LWP::UserAgent->new;
    $ua->timeout( $args->{timeout} || 10 );
    $ua->agent($ENV{HTTP_PROXY_AGENT} || ("$0/$Tk::Wizard::Installer::VERSION " . $ua->agent));

    if (defined $args->{proxy}){
        $proxy_user = $args->{HTTP_PROXY_USER};
        $proxy_pass = $args->{HTTP_PROXY_PASS};
        warn ("read_uri: calling env_proxy: $args->{http_proxy}") if $self->{-debug};
        $ua->env_proxy;
	} elsif (defined $ENV{HTTP_PROXY}) {
        $proxy_user = $ENV{HTTP_PROXY_USER};
        $proxy_pass = $ENV{HTTP_PROXY_PASS};
        warn ("read_uri: calling env_proxy: $ENV{HTTP_proxy}") if $self->{-debug};
        $ua->env_proxy;
    }

    my $req = HTTP::Request->new(GET => $args->{uri});
    if (defined $proxy_user and defined $proxy_pass) {
        warn ("read_uri: calling proxy_authorization_basic($proxy_user, $proxy_pass)") if $self->{-debug};
        $req->proxy_authorization_basic($proxy_user, $proxy_pass);
    }

	# set the progress bar

	# update the progress bar
 	($self->{response}, $self->{bytes_transferred}) = (undef, 0);
	$self->{response} = $ua->request(
		$req,
		sub { &lwp_callback($self,$args->{bar},@_) },
		, 4096
	);

	if ($self->{response} && $self->{response}->is_success) {
		my ($dirs,$file) = $args->{target} =~ /^(.*?)([^\\\/]+)$/;
		if ($dirs and $dirs!~/^\.{1,2}$/ and !-d $dirs){
			mkpath $dirs or croak "Could not make path $dirs : $!";
		}
		unless (open OUT, ">$args->{target}") {
			warn ("read_uri: Couldn't open $args->{target} for writing") if $self->{-debug};
			$self->{errstr} = "Couldn't open $args->{target} for writing\n";
			return;
		}
		warn "# Writing to $args->{target}...\n" if $self->{-debug};
		binmode OUT;
		print OUT $self->{response}->content;
		close OUT;
        return 1;
    }
    if ($self->{response}) {
        warn ("read_uri: Error(1) reading $args->{uri}: ".$self->{response}->code." ".
            $self->{response}->message) if $self->{-debug};
        $self->{errstr} = "Error(1) reading $args->{uri}: ".$self->{response}->code. " " .
            $self->{response}->message . "\n";
    }
    else {
        warn ("read_uri: Error(2) reading $args->{uri} ") if $self->{-debug};
        $self->{errstr} = "Error(2) reading $args->{uri} 	\n";
    }
    return 0;
}


# c/o PPM.pm
sub lwp_callback { my $self=shift;
	my ($bar, $data, $res, $protocol) = @_;
	$bar->configure( -to => $res->header('Content-Length') );
#	$bar->configure(-to => $res->{_headers}->content_length);
	$bar->value( $bar->value + length $data );
	$bar->update;
    $self->{response} = $res;
    $self->{response}->add_content($data);
    $self->{bytes_transferred} += length $data;
}


sub download_again { my ($self,$failed) = (shift,shift);
	my $button = $self->parent->messageBox(
		-icon => 'question',
		-type => 'yesno',
		-default => 'yes',
		-title => 'File Download',
		-message => $failed." file".($failed!=1?"s":"")." were not downloaded.\n\nWould you like to try again?",
	);
	return lc $button eq 'yes'? 1:0;
}

sub download_quit { my ($self,$failed) = (shift,shift);
	my $button = $self->parent->messageBox(
		-icon => 'error',
		-type => 'yesno',
		-default => 'no',
		-title => 'Abort Installation?',
		-message => "Without downloading the remaining $failed file"
		.($failed!=1?"s":"")
		.", the Installer cannot complete the installation.\n\n"
		."Should the Installation process be aborted?",
	);
	$self->CloseWindowEventCycle if lc $button eq 'yes';
}


1;
__END__

=head1 INTERNATIONALISATION

The labels of the licence can be changed (perhaps into a language other an English)
by changing the values of the package-global C<%LABELS> hash, at the top of the source.
This will be revised in a future version.

Please see other functions' arguemnts for label-changing paramters.

=head1 CAVEATS / TODO / BUGS

=over 4

=item *

It would be nice to have an 'Estimated Time Remaining' feature for the copy routines.

=item *

How about a remove-before-copy feature, and removing of directories?  When there is time, yes.

=cut

=head1 SEE ALSO

L<Tk::LabFrame>; L<File::Path>; L<Tk::ProgressBar>; L<File::Spec>; L<File::Copy>; L<Tk>; L<Tk::Wizard>; L<Tk::Wizard::Install::Win32>.

=head1 AUTHOR

Lee Goddard (lgoddard @ cpan.org).

=head1 KEYWORDS

Wizard; set-up; setup; installer; uninstaller; install; uninstall; Tk; GUI.

=head1 COPYRIGHT

Copyright (C) Lee Goddard, 11/2002 ff.

Available under the same terms as Perl itself; no warranty of any kind.


