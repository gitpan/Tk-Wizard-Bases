package Tk::Wizard::Installer;
use vars qw/$VERSION/;
$VERSION = 0.0212;	# why was adddirselectpage here?!

=head1 NAME

Tk::Wizard::Installer - building-blocks for a software install wizard

=cut

BEGIN {
	use Carp;
	use Cwd;
	use File::Path;
	use File::Copy;
	use File::Spec;
	use Tk::Wizard;
	use Tk::ProgressBar;
	use Tk::LabFrame;
	require Exporter;
	@ISA = "Tk::Wizard";
	@EXPORT = ("MainLoop");
}

# See INTERNATIONALISATION

my %LABELS = (
	# Buttons
	BACK => "< Back",	NEXT => "Next >",
	FINISH => "Finish",	CANCEL => "Cancel",
	HELP => "Help", OK => "OK",

	# licence agreement
	LICENCE_ALERT_TITLE	=> "Licence Condition",
	LICENCE_OPTION_NO	=> "I do not accept the terms of the licence agreement",
	LICENCE_OPTION_YES	=> "I accept the terms the terms of the licence agreement",
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
dependant upon Perl, try Inno Setup - C<http://www.jrsoftware.org/>. It's
so good, even Microsoft have been caught using it.

Your contributions to extend it are more than welcome!

=head1 DEPENDENCIES

	Tk::Wizard;
	Tk::ProgressBar;
	Tk::LabFrame;

=head1 DETAILS

C<Tk::Wizard::Installer> supports of the methods and means of C<Tk::Wizard>
(see L<Tk::Wizard>),
plus those listed in the remainder of this document.

=head1 METHOD addLicencePage

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
		-text	 =>"\n"
	);
	my $t = $frame->Scrolled(
		qw/ROText -relief sunken -borderwidth 2 -font SMALL_FONT -width 10 -setgrid true
		-height 9 -scrollbars e -wrap word/
	);

	$t->insert('0.0', $text);
	$t->configure(-state => "disabled");
	$t->pack(qw/-expand 1 -fill both -padx 10 /);
	$frame->Frame(-height=>10)->pack();
	$_ = $frame->Radiobutton(
		-font => $self->{defaultFont},
		-text     => $LABELS{LICENCE_OPTION_YES},
		-variable => \${$self->{licence_agree}},
		-relief   => 'flat',
		-value    => 1,
		-underline => '2',
		-anchor	=> 'w',
		-background=>$self->cget("-background"),
	)->pack(-padx=>$padx, -anchor=>'w',);
	$frame->Radiobutton(
		-font => $self->{defaultFont},
		-text     => $LABELS{LICENCE_OPTION_NO},
		-variable => \${$self->{licence_agree}},
		-relief   => 'flat',
		-value    => 0,
		-underline => 5,
		-anchor	=> 'w',
		-background=>$self->cget("-background"),
    )->pack(-padx=>$padx, -anchor=>'w',);
	return $frame;
}


=head1 CALLBACK callback_licence_agreement

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


=head1 METHOD addDirSelectPage

See L<TK::Wizard/METHOD adddirSelectPage>.


=head1 METHOD addFileListPage

	$wizard->addFileListPage ( name1=>value1 ... nameN=>valueN )

Adds a page (C<Tk::Frame>) that contains a contains a progress bar
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

=item -continue

Display the next Wizard page once the job is done: invokes the callback
of the I<Next> button at the end of the task.

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
	$args->{-bar} = $f->ProgressBar( %bar )->pack(
		qw/ -padx 20 -pady 10 -side top -anchor w -fill both -expand 1 /
	);
	$f->pack(qw/-fill x -padx 30/);

	$args->{-bar}->after ( $args->{-delay} || 1000, sub {
		$self->{nextButton}->configure(-state=>"disable");
		$self->{backButton}->configure(-state=>"disable");

		$args->{-bar}->configure(-to => $self->pre_install_files($args) );
		$self->install_files($args);

		$self->{nextButton}->configure(-state=>"normal");
		$self->{backButton}->configure(-state=>"normal");
		$self->{nextButton}->invoke if $args->{-continue};
	});
	return $frame;
}


# Pre-parse, counting files and expanding directories if necessary
# Return total number of files to process
sub pre_install_files { my ($self,$args) = (shift,shift);
	croak "Arguments should be supplied as a hash ref" if not ref $args or ref $args ne "HASH";
	croak "-from and -to are different lengths" if $#{$args->{-from}} != $#{$args->{-from}};
	my $total = 0;
	my $i=-1;
	$args->{-labelDir}->configure(-text => $args->{-label_preparing} || "Preparing..." ) ;
	$args->{-labelDir}->update;
	$args->{-labelFile}->configure(-text => "") ;
	$args->{-labelDir}->update;

	my @to   = @{ $args->{-to  } };
	my @from = @{ $args->{-from} };

	foreach (@to){
		$i++;
		# Directories:
		if (-d $from[$i]){
			local *DIR;
			my $orig_dir = cwd;
			chdir $from[$i] or die "Weird dir error";
			opendir DIR,".";
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
		} else {
			croak "Could not read file ",@{$args->{-from}}[$i];
		}
	}
	return $total+1;
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
			$args->{-bar}->value( $args->{-bar}->value +1 );
			$args->{-bar}->update;

			# Make the path, if needs be
			my $d = "$tv/$td";
			$d =~ s/[\\\/]+/\//g;
			if (!-d "$d"){
				mkpath $d or croak "Could not make path $d : $!";
			}

			# Do the move/copy
			if ($args->{-move}){
				move @{$args->{-from}}[$i],@{$args->{-to}}[$i];
			} else {
				copy @{$args->{-from}}[$i],@{$args->{-to}}[$i];
			}
		} else {
			croak "Could not read file ",@{$args->{-from}}[$i];
		}
	}
	return $total+1;
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


