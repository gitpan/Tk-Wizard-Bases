package Tk::Wizard;

=head1 NAME

Tk::Wizard - GUI for step-by-step interactive logical process

=cut

use vars qw/$VERSION/;
$VERSION = 1.037;	# 03 April 2003


# Still alpha.

BEGIN {
	use Carp;
	use Tk;
	use Tk::DirTree;
	use File::Path;
	use Tk::ROText;
	require Exporter;			# Exporting Tk's MainLoop so that
	@ISA = "Exporter";			# I can just use strict and Tk::Wizard without
	@EXPORT = ("MainLoop");		# having to use Tk
}

use strict;
if ($^V and $^V gt v5.8.0){
	eval "use warnings";
}
use base  qw(Tk::MainWindow);
Tk::Widget->Construct('Wizard');

use vars qw/%LABELS %DRIVETYPES/;

# See INTERNATIONALISATION
%LABELS = (
	# Buttons
	BACK => "< Back",	NEXT => "Next >",
	FINISH => "Finish",	CANCEL => "Cancel",
	HELP => "Help", OK => "OK",
);

# Only used in Win32: see &page_dirSelect
%DRIVETYPES = (
	3=>1, 4=>1,6=>1,
);


=head1 SYNOPSIS

	use Tk::Wizard;
	my $wizard = new Tk::Wizard(
		-title		=> "TitleBar Title",
		-imagepath	=> "/image/for/the/left/panel.gif",
	);
	$wizard->configure( ...add event handlers... );
	$wizard->cget( ...whatever... );
	$wizard->addPage(
		... code-ref to anything returning a Tk::Frame ...
	);
	$wizard->addPage( sub {
		return $wizard->blank_frame(
			-title	=> "Page Title",
			-text	=> "Some text.",
		);
	});
	$wizard->Show;
	MainLoop;
	__END__

To avoid 50 lines of SYNOPSIS, please see the files included with the distribution.
in the test directory: F<t/*.t>. These are just Perl files that are run during
the C<make test> phase of installation: you may rename them without harm once
you have installed the module.

=head1 DEPENDENCIES

C<Tk> and modules of the current standard Perl Tk distribution.

On MS Win32 only: C<Win32API::File>.

=head1 EXPORTS

	MainLoop();

This is so that I can say C<use strict; use Tk::Wizard> without
having to C<use Tk>. You can always C<use Tk::Wizard ()> to avoid
importing this.

=head1 DESCRIPTION

In the context of this namespace, a Wizard is defined as a graphic user interface (GUI)
that presents information, and possibly performs tasks, step-by-step via a series of
different pages. Pages (or 'screens', or 'Wizard frames') may be chosen logically depending
upon user input.

The C<Tk::Wizard> module automates a large part of the creation of a wizard program
to collect information and then perform some complex task based upon it.

The wizard feel is largly based upon the Microsoft(TM,etc) wizard style: the default is
simillar to that found in Microsoft Windows 95; a more Windows 2000-like feel is also
supported (see the C<-style> entry in L<WIDGET-SPECIFIC OPTIONS>. Sub-classing the
module to provide different look-and-feel is highly encourage: please see
L<NOTES ON SUB-CLASSING Tk::Wizard>.

NB: B<THIS IS AN ALPHA RELEASE: ALL CONTRIBUTIONS ARE WELCOME!>

Please also see L<IMPLIMENTATION NOTES>.

=head1 STANDARD OPTIONS

    -title -background -width -height

Please see the L<Tk::options> documentation for details of the standard options.

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item Name:   style

=item Class:  ""

=item Switch: -style

Sets the display style of the Wizard.

The default C<95> value creates a traditional, Windows 95-style wizard,
with every page being C<SystemButtonFace> coloured, with a large image on the
left (C<-imagepath>, below).

A value of C<top>, the Wizard will be more of a Windows 2000-like affair,
with the initial page being a white-backgrounded version of the traditional style,
and subsequent pages being C<SystemButtonFace> coloured, with a white
strip at the top holding a title and subtitle, and a smaller image (see C<-topimagepath>,
below).

=item Name:   imagepath

=item Class:  ""

=item Switch: -imagepath

Path to an image file that will be displayed on the left-hand side of the screen.
Dimensions are not been restrained (yet).

Notes:

=over 4

=item *

This is a C<Tk::Photo> object without the format being specified - this has been
tested only on GIF and JPEG.

=item *

No checking is done, but paths ought to be absolute, as no effort is made to
maintain or restore any initial current working directory.

=item *

The supplied images F<wizard_blue.gif> and F<wizard_blue_top.gif> are used by default.
If you supply others you will probably have to set the Wizard's C<-width> and
C<-height> properties, as there is (currently) no image-sized checking performed.

=back

=item Name:   topimagepath

=item Class:  ""

=item Switch: -topimagepath

Only required if C<-style=E<gt>'top'> (as above): the image this filepath specifies
will be displayed in the top-right corner of the screen. Dimensions are not
restrained (yet), but only 50px x 50px has been tested.

Please see notes for the C<-imagepath> entry, above.

=item Name:   nohelpbutton

=item Class:  ""

=item Switch: -nohelpbutton

Set to anything to disable the display of the I<Help> buton.

=item Name:   resizable

=item Class:  ""

=item Switch: -resizable

Supply a boolean value to allow resizing of the window: default
is to disable that feature to minimise display issues.

=item Switch: -tag_text

Text to supply in a 'tag line' above the wizard's control buttons.

=item Switch: -tag_width

Width for C<-tag_text>, above: when I work out better C<pack>ing,
this will no longer be needed. Default value is 75 pixels.

=item Switch: -tag_disable

Disables display of the C<-tag_text>, above.

=back

Please see also L<ACTION EVENT HANDLERS>.

=cut

sub Populate { my ($cw, $args) = @_;
    $cw->SUPER::Populate($args);
    $cw->ConfigSpecs(
# ?		-title			=> ['SELF','title','Title','Generic Wizard'],
# ?		-resizable		=> ['SELF','resizable','Resizable',undef],
		-command    	=> ['CALLBACK', undef, undef, undef ],
#		-foreground 	=> ['PASSIVE', 'foreground','Foreground', 'black'],
		-background 	=> ['METHOD', 'background','Background',
		$^O=~/(MSWin32|cygwin)/i? 'SystemButtonFace':'gray'],
		-style			=> ['PASSIVE',"style","Style","95"],
		-imagepath		=> ['PASSIVE','topimagepath', 'Imagepath', undef],
		-topimagepath	=> ['PASSIVE','topimagepath', 'Topimagepath', undef],
		# event handling references
		-nohelpbutton			=> ['PASSIVE',undef,undef,undef],
		-preNextButtonAction    => ['PASSIVE',undef,undef,undef],
		-postNextButtonAction   => ['PASSIVE',undef,undef,undef],
		-preBackButtonAction    => ['PASSIVE',undef,undef,undef],
		-postBackButtonAction   => ['PASSIVE',undef,undef,undef],
		-preHelpButtonAction    => ['PASSIVE',undef,undef,undef],
		-helpButtonAction       => ['PASSIVE',undef,undef,undef],
		-postHelpButtonAction   => ['PASSIVE',undef,undef,undef],
		-finishButtonAction     => ['PASSIVE',undef,undef,undef],
		-preCancelButtonAction 	=> ['CALLBACK',undef, undef, sub { &DIALOGUE_really_quit($cw) }],
		-preCloseWindowAction	=> ['CALLBACK',undef, undef, sub { &DIALOGUE_really_quit($cw) }],
		-tag_text				=> ['PASSIVE',"tag_text","TagText","Perl Wizard"],
		-tag_width				=> ['PASSIVE',"tag_width","TagWidth",75],
	);

	$cw->{wizardPageList}	= [];
	$cw->{wizardPagePtr}	= 0;
	$cw->{wizardFrame}		= 0;
	$cw->{-imagepath}		= ""	|| $args->{-imagepath};
	$cw->{-topimagepath}	= "" 	|| $args->{-topimagepath};
	$cw->{-style}			= "95"	|| $args->{-style};
	$cw->{background_userchoice} = $args->{-background} || $cw->ConfigSpecs->{-background}[3];
	$cw->{background} = $cw->{background_userchoice};
	$args->{-title}  = "Generic Wizard" unless $args->{-title};
	$args->{-style} = $cw->{-style} unless $args->{-style};	# yuck
	$args->{-width } = ($args->{-style} eq 'top'? 500 : 570) unless $args->{-width};
	$args->{-height} = 370 unless $args->{-height};
	# $cw->overrideredirect(1);
	my $buttonPanel = $cw->Frame;
	# right margin
	$buttonPanel->Frame(-width=>10)->pack( -side => "right", -expand => 0,-pady=>10);
	# Bottom
	$cw->{cancelButton} = $buttonPanel->Button( -text => $LABELS{CANCEL},
		-command => [ \&CancelButtonEventCycle, $cw, $cw],-width => 10,
	) ->pack( -side => "right", -expand => 0,-pady=>10);
	$buttonPanel->Frame(-width=>10)->pack( -side => "right", -expand => 0,-pady=>10);
	$cw->{nextButton} = $buttonPanel->Button( -text => $LABELS{NEXT},
		-command => [ \&NextButtonEventCycle, $cw ],
		-width => 10
	)->pack( -side => "right", -expand => 0,-pady=>10);
	$cw->{backButton} = $buttonPanel->Button( -text => $LABELS{BACK},
		-command => [ \&BackButtonEventCycle, $cw ],
		-width => 10,
		-state => "disabled"
	)->pack( -side => "right", -expand => 0,-pady=>10);
	if ($cw->cget(-nohelpbutton)){
		$cw->{helpButton} = $buttonPanel->Button( -text => $LABELS{HELP},
			-command => [ \&HelpButtonEventCycle, $cw ],
			-width => 10,
		)->pack( -side => 'left', -anchor => 'w',-pady=>10,-padx=>10);
	}
	$buttonPanel->pack(qw/ -side bottom -fill x/);
	# Container for line/tag
	my $tagbox = $cw->Frame(
		-width => $cw->cget(-width)-($args->{-tag_width}||75)||450,
#		-background=>$cw->cget(-background),
		-height => 12,
	)->pack(qw/-side bottom -fill x/);

	# Tag text
	$args->{-tag_text} = "Perl Wizard" unless exists $args->{-tag_text};
	$args->{-tag_width} = 80 unless exists $args->{-tag_width};
	$cw->fontCreate(qw/TAG -family verdana -size 8 -weight bold/);
	$cw->{tagtext} = $tagbox->Canvas(
		-relief	=> 'flat',
		-border => 1,
		-height => 12,
		-width => $args->{-tag_width},
	)->pack(qw/-side left -anchor w/);
	$cw->{tagtext}->createText(2,7,-text=>$args->{-tag_text},-fill=>'#999999',-anchor=>'w',-font=>'TAG',);
	$cw->{tagtext}->createText(2,9,-text=>$args->{-tag_text},-fill=>'white',-anchor=>'w',-font=>'TAG',);
	$cw->{tagtext}->createText(2,8,-text=>$args->{-tag_text},-fill=>'gray',-anchor=>'w',-font=>'TAG',);

	# Line above buttons
	$cw->{tagline} = $tagbox->Frame(
		-width => $cw->cget(-width)||500,
		-background=>$cw->cget(-background),
		qw/ -relief groove -bd 1 -height 2/,
	)->pack(qw/-side left -anchor e/);

	# Desktops for dir select: thanks to Slaven Rezic who also suggested SHGetSpecialFolderLocation for Win32. l8r
	if ($^O =~ /(MSWin32|cygwin)/i and -d "$ENV{USERPROFILE}/Desktop"){
		# use OLE;
		$cw->{desktop_dir} = "$ENV{USERPROFILE}/Desktop"
	} elsif (-d "$ENV{HOME}/Desktop"){
		$cw->{desktop_dir} = "$ENV{HOME}/Desktop";
	} elsif (-d "$ENV{HOME}/.gnome-desktop"){
		$cw->{desktop_dir} = "$ENV{HOME}/.gnome-desktop";
	}
	# Font used for &blank_frame titles
	$cw->fontCreate(qw/TITLE_FONT -family verdana -size 12 -weight bold/);
	# Font used in multiple choices for radio title
	$cw->fontCreate(qw/RADIO_BOLD -family verdana -size 8 -weight demi/);
	# Fonts used if -style=>"top"
	$cw->fontCreate(qw/TITLE_FONT_TOP -family verdana -size 8 -weight bold/);
	$cw->fontCreate(qw/SUBTITLE_FONT  -family verdana -size 8 /);
	# Font used in licence agreement	XXX REMOVE TO CORRECT MODULE
	$cw->fontCreate(qw/SMALL_FONT -family verdana -size 8 /);
	# Font used in all other places
	$cw->fontCreate(qw/DEFAULT_FONT -family verdana -size 8 /);
	$cw->{defaultFont} = 'DEFAULT_FONT';
}


sub background { my ($self,$operand)=(shift,shift);
	if (defined $operand){
#		warn "set bg to $operand";
		$self->{background} = $operand;
		return $operand;
	}
	elsif ($self->{wizardPagePtr}==0 or $self->{wizardPagePtr}==$#{$self->{wizardPageList}}){
#		warn "pages are such ($self->{wizardPagePtr}) that bg is set to white from $self->{background}";
		$self->{background} = 'white';
		return 'white';
	} else {
		$self->{background} = $self->{background_userchoice};
		return $self->{background};
	}
}


=head2 METHOD addPage

	$wizard->addPage ($page_code_ref1 ... $page_code_refN)

Adds a page to the wizard. The parameters must be references to code that
evaluate to C<Tk::Frame> objects, such as those returned by the methods C<blank_frame>
and C<addDirSelectPage>.

Pages are (currently) stored and displayed in the order added.

Returns the index of the page added, which is useful as a page UID when peforming
checks as the I<Next> button is pressed (see file F<test.pl> supplied with the distribution).

See also L<METHOD blank_frame> and L<METHOD addDirSelectPage>.

=cut

sub addPage { my ($self, @pages) = (shift,@_);
	if (grep {ref $_ ne 'CODE'} @pages){
		croak "addPage requires one or more CODE references as arguments"
	}
	push @{$self->{wizardPageList}}, @pages;
}


=head2 METHOD Show

	C<wizard>->Show()

This method must be dispatched before the Wizard will be displayed,
and must preced the C<MainLoop> call.

=cut

sub Show { my $self = shift;
	if ($^W and $#{$self->{wizardPageList}}==0){
		warn "Showing a Wizard that is only one page long";
	}

	$self->initial_layout;
	$self->render_current_page;

	$self->resizable( 0, 0)	unless $self->{-resizable} and $self->{-resizable} =~/^(1|yes|true)$/i;
	$self->withdraw;                # position in screen center
	$self->Popup;
	$self->transient;               # forbid minimize
	$self->protocol( WM_DELETE_WINDOW => [ \&CloseWindowEventCycle, $self, $self]);
	$self->packPropagate(0);
	$self->configure("-background"=>$self->cget("-background"));
} # end of sub Show


=head2 METHOD forward

Convenience method to move the Wizard on a page by invoking the
callback for the C<nextBUtton>.

You can automatically move forward after C<$x> tenths of a second
by doing something like this:

	$frame->after($x,sub{$wizard->forward});

=cut

sub forward { my $self=shift;
	return $self->{nextButton}->invoke;
}

=head2 METHOD backward

Convenience method to move the Wizard back a page by invoking the
callback for the C<backBUtton>.

See also L<METHOD back>.

=cut

sub backward { my $self=shift;
	return $self->{backButton}->invoke;
}


#
# Sub-class me!
# Called by Show().
#
sub initial_layout { my $self = shift;
	if ($^W and $self->cget(-style) eq 'top' and not $self->cget(-topimagepath)){
		warn "Wizard has -style=>top but not -topimagepath is defined";
	}
	# Wizard 98/95 style
	if ($self->cget(-style) eq '95' or $self->{wizardPagePtr}==0){
		if ($self->cget(-imagepath)){
			$self->Photo( "sidebanner",  -file => $self->cget(-imagepath));
			$self->{left_object} = $self->Label( -image => "sidebanner")->pack( -side => "top", -anchor => "n");
		} else {
			$self->{left_object} = $self->Frame(-width=>100)->pack(qw/-side left -anchor w -expand 1 -fill both/);
		}
	}
	# Wizard 2k style - builds the left side of the wizard
	else {
		if ($self->cget(-topimagepath)){
			$self->Photo( "sidebanner", -file => $self->cget(-topimagepath));
			$self->{left_object} = $self->Label( -image => "sidebanner")->pack( -side => "top", -anchor => "e", );
		} else {
			$self->{left_object} = $self->Frame( -width => 250 )->pack( -side => "top", -anchor => "n", -padx=>5, -pady=>2);
		}
	}
}


#
# Maybe sub-class me
#
sub render_current_page { my $self = shift;
	if ($self->{wizardPagePtr} > 0
	and $self->{wizardPagePtr} < $#{$self->{wizardPageList}}){
		$self->{tagtext}->packForget;
		$self->{tagline}->packForget;
		$self->{tagtext}->pack(qw/-side left -anchor w/);
		$self->{tagline}->pack(qw/-side left -anchor e/);
	} else {
		$self->{tagtext}->packForget;
		$self->{tagline}->pack(qw/-side left -anchor e/);
	}

	if (($self->cget(-style) eq 'top' and $self->{wizardPagePtr} == 0)
		or $self->{wizardPagePtr} == $#{$self->{wizardPageList}}
	){
		$self->{left_object}->pack( -side => "left", -anchor => "w");
	} elsif ($self->cget(-style) eq 'top'){
		$self->{left_object}->packForget;
	}
	# xxx
	$self->configure("-background"=>$self->cget("-background"));
	$self->{nextButton}->focus(); # Default focus possibly over-ridden in wizardFrame
	$self->{wizardFrame}->packForget if $self->{wizardFrame};
	$self->{wizardFrame} = $self->{wizardPageList}->[$self->{wizardPagePtr}]->()->pack(qw/-side top/);
}



=head2 METHOD currentPage

	my $current_page = $wizard->currentPage()

This returns the index of the page currently being shown to the user.
Page are indexes start at 1, with the first page that is associated with
the wizard through the C<addPage> method. See also the L<METHOD addPage> entry.

=cut

sub currentPage { my $self = shift;
	return ($self->{wizardPagePtr} + 1);
}

=head2 METHOD parent

	my $apps_main_window = $wizard->parent;

This returns a reference to the parent Tk widget that was used to create the wizard.
Returns a reference to the Wizard's C<MainWindow>.

=cut

sub parent { return shift }


=head2 METHOD blank_frame

	my $frame = wizard>->blank_frame(-title=>$title,-subtitle=>$sub,-text=>$standfirst);

Returns a C<Tk::Frame> object that is a child of the Wizard control, with some C<pack>ing
parameters applied - for more details, please see C<-style> entry elsewhere in this document.

Arguments are name/value pairs:

=over 4

=item -title =>

Printed in a big, bold font at the top of the frame as a title

=item =subtitle =>

Subtitle/standfirst.

=item -text =>

Main body text.

=back

Also:

	-width -height -background -font

See also L<METHOD addDirSelectPage>.

=cut

#
# Sub-class me:
#	accept the args in the POD and
#	return a Tk::Frame
#
sub blank_frame { my ($self,$args) = (shift,{@_});
	my ($main_bg,$main_wi);
	my $wrap = $args->{-wraplength} || 375;
	$args->{-font} = $self->{defaultFont} unless $args->{-font};
	# First and last pages are white
	if ($self->{wizardPagePtr}==0
		or $self->{wizardPagePtr} == $#{$self->{wizardPageList}}
	){
		$main_bg = $self->cget("-background"); # was white
		$main_wi = $args->{-width} || 300;
	}
	# For 'top' style, main body is user choice (undef  by default)
	elsif ($self->cget(-style) eq 'top' and $self->{wizardPagePtr}>0){
		$main_bg = $self->cget("-background");# undef;
		$main_wi = $args->{-width} || 600
	}
	# For other styles (95 default), main body is userdefined or plain
	else {
		$main_bg = $args->{background} || $self->cget("-background");
		$main_wi = $args->{-width} || 300;
	}
	# Frame is the page container
	my $frame = $self->parent->Frame( -width=>$main_wi, -height=>$args->{-height}||316, );
#	my $frame = $self->parent->Scrolled("Frame", -scrollbars=>'osoe',-width=>$main_wi, -height=>$args->{-height}||316, );
	$frame->configure(-background => $main_bg) if $main_bg;

	# For 'top' style pages other than first and last
	if (($self->cget(-style) eq 'top' and $self->{wizardPagePtr}>0)
	and $self->{wizardPagePtr} != $#{$self->{wizardPageList}}
	){
		my $top_frame = $frame->Frame(-background=>'white')->pack(-fill=>'x',-side=>'top',-anchor=>'e');
 		$_ = $top_frame->Frame(-background=>'white');
		$_->Photo( "topimage", -file => $self->cget(-topimagepath));
		$_->Label( -image => "topimage")->pack( -side=>"right", -anchor=>"e", -padx=>5,-pady=>5);
		$_->pack(-side=>'right',-anchor=>'n');
		my $title_frame = $top_frame->Frame(-background=>'white')->pack(
			-side=>'left',-anchor=>'w',-expand=>1,-fill=>'x'
		);
		#
		# Is it better to call in Text::Wrap to indent, or
		# access font metrics and work out lengths and heights, or
		# just sod it and only support short lines?
		#
		if ($args->{-title}){
			# Indent left of title: -height should come from font metrics of TITLE_FONT_TOP;
			# 	but what about if the line wraps?
			$title_frame->Frame(qw/-background white -width 30 -height 30/)->pack(qw/-fill x -anchor n -side left/);
			$title_frame->Label(
				-justify => 'left', -anchor=> 'w', -wraplength=>$wrap,
				-text=> $args->{-title},
				-font=>'TITLE_FONT_TOP', -background=>"white",
			)->pack(-side=>'top',-expand=>'1',-fill=>'x',-pady=>5,-padx=>5);
		}
		# Smaller text in top
		if ($args->{-subtitle}){
			# Indent the subtitle - see note above
			$title_frame->Frame(qw/-background white -width 20 -height 12/)->pack(qw/-fill x -anchor w -side left/);
			$args->{-subtitle} =~ s/^[\n\r\f]//;
			$args->{-subtitle} = $args->{-subtitle};
			$title_frame->Label(
				-font => 'SUBTITLE_FONT',
				-justify => 'left',
				-anchor=> 'w',
				-wraplength=>$wrap, qw/-justify left/, -text => $args->{-subtitle},
				-background=>$args->{background}||"white",
			)->pack(-side=>'top',-expand=>'1',-fill=>'x',-padx=>5,);
		} else {
			$frame->Label(); # intended so we can packForget first to $frame->children;
		}

		# Line below top
		if ($self->cget(-style) eq 'top' and $self->{wizardPagePtr}>0){
			my $top = $frame->Frame(
				-width => ($frame->cget(-width)||500),
				-background => $frame->cget("-background"),
				qw/ -relief groove -bd 1 -height 2/,
			)->pack(qw/-side top -fill x/);
		}

		# Text in body
		if ($args->{-text}){
			$args->{-text} =~ s/^[\n\r\f]//;
			$args->{-text} = "\n".$args->{-text};
			$_ = $frame->Label(
				-font => $args->{-font},
				-justify => 'left',  -anchor=> 'w',
				-wraplength => $wrap + 100,
				-justify => "left", -text => $args->{-text}
			)->pack(-side=>'top',-expand=>'1',-fill=>'x',-padx=>10);
			$_->configure(-background => $main_bg) if $main_bg ;
		}

	}

	# For wizards that are not 'top' style
	else {
		if ($args->{-title}){
			$_ = $frame->Label(
				-justify => 'left', -anchor=> 'w',
				-wraplength=>$wrap, -text=>$args->{-title}, -font=>'TITLE_FONT',
			)->pack(-anchor=>'n',-side=>'top',-expand=>1,-fill=>'x');
			$_->configure(-background=>$main_bg) if $main_bg;
		}
		if ($args->{-subtitle}){
			$args->{-subtitle} =~ s/^[\n\r\f]//;
			$args->{-subtitle} = "\n".$args->{-subtitle};
			$_ = $frame->Label(
				-font => $args->{-font},
				-justify => 'left',
				-anchor=> 'w',
				-wraplength=>$wrap, qw/-justify left/, -text => $args->{-subtitle},
			)->pack(-anchor=>'n',-side=>'top',-expand=>'1',-fill=>'x');
			$_->configure(-background=>$main_bg) if $main_bg;
		} else {
			$frame->Label(); # intended so we can packForget first to $frame->children;
		}
		if ($args->{-text}){
			$args->{-text} =~ s/^[\n\r\f]//;
			$args->{-text} = "\n".$args->{-text};
			$_ = $frame->Label(
				-font => $args->{-font},
				-justify => 'left',
				-anchor=> 'w',
				-wraplength=>$wrap, qw/-justify left/, -text => $args->{-text},
			)->pack(-anchor=>'n',-side=>'top',-expand=>'1',-fill=>'x');
			$_->configure(-background=>$main_bg) if $main_bg;
		} else {
			$frame->Label(); # intended so we can packForget first to $frame->children;
		}
	}
#	$_ = $frame->Frame->pack(qw/-anchor s -side bottom -fill both -expand 1/);
#	$_->configure(-background => $frame->cget("-background") );
#	$_->packPropagate(0);

	return $frame->pack(qw/-side top -anchor n -fill x/);
} # end blank_frame



=head1 METHOD addTextFrame

Add to the wizard a frame containing a scroll box of text,
specified in the paramter C<-boxedtext>. If this is a reference
to a scalar, it is taken to be plain text;
if a plain scalar, it is taken to be a file to be opened and
read.

Accepts the usual C<-title>, C<-subtitle>, and C<-text> like C<blank_frame>.

=cut

sub addTextFrame { my ($self,$args) = (shift,{@_});
	return $self->addPage( sub { $self->text_frame($args)  } );
}


sub text_frame { my ($self,$args) = (shift,{@_});
	local *IN;
	my $text;
	my $frame = $self->blank_frame(@_);
	if ($args->{-boxedtext}){
		if (ref $args->{-boxedtext} eq 'SCALAR'){
			$text = $args->{-boxedtext};
		} elsif (not ref $args->{-boxedtext}){
			open IN,$args->{-boxedtext} or croak "Could not read file: $args->{-boxedtext}; $!";
			read IN,$$text,-s IN;
			close IN;
		}
	}
	$$text = "" if not defined $text;

	my $padx = $self->cget(-style) eq 'top'? 30 : 5;
	my $t = $frame->Scrolled("ROText",
		-background => ($args->{"-background"} || 'white'),
		-relief => "sunken",
		-borderwidth => "1",
		-font => "SMALL_FONT",
		-setgrid => 1,
		-scrollbars => "osoe",
		-wrap => "word",
	);
	$t->insert('0.0', $$text);
	$t->configure(-state => "disabled");
	$t->pack(qw/-expand 1 -fill both -padx 10 -pady 10/);
	$frame->Frame(-height=>10)->pack();
	return $frame;
}


#
# Method:       dispatch
# Description:  Thin wrapper to dispatch event cycles as needed
# Parameters:    The dispatch function is an internal function used to determine if the dispatch back reference
#         is undefined or if it should be dispatched. Undefined methods are used to denote dispatchback
#         methods to bypass. This reduces the number of method dispatchs made for each handler and also
#         increased the usability of the set methods above when trying to unregister event handlers.
#
sub dispatch { my $handler = shift;
	return (!($handler->())) if defined $handler;
	return 0;
} # end of sub dispatch

#
# Method:      NextButtonEventCycle
# Description: Runs the complete view of the action handler cycle for the "Next>" button on the
#              wizard button bar. This includes dispatching the preNextButtonAction and
#              postNextButtonAction handler at the apporprate times.
#
sub NextButtonEventCycle { my $self = shift;
	if( dispatch( $self->cget(-preNextButtonAction) )) { return;}
	# advance the wizard page pointer and then adjust the navigation buttons.
	# readraw the frame when finished to get changes to take effect.
	$self->{wizardPagePtr}++;
	$self->{wizardPagePtr} = $#{$self->{wizardPageList}} if( $self->{wizardPagePtr} >= $#{ $self->{wizardPageList}});
	$self->{backButton}->configure( -state => "normal");
	if( $self->{nextButton}->cget( -text) eq $LABELS{FINISH}) {
		if( dispatch( $self->cget(-finishButtonAction))) { return; }
		$self->CloseWindowEventCycle();
	}
	if ($self->{wizardPagePtr} == $#{ $self->{wizardPageList}}){
		$self->{nextButton}->configure( -text => $LABELS{FINISH}) ;
		$self->{cancelButton}->packForget();
		$self->{backButton}->packForget();
	}
	$self->render_current_page;
	if( dispatch( $self->cget(-postNextButtonAction))) { return; }
}

sub BackButtonEventCycle { my $self=shift;
	return if dispatch( $self->cget(-preBackButtonAction));
	# move the wizard pointer back one position and then adjust the navigation buttons
	# to reflect any state changes. Don't fall off end of page pointer
	$self->{wizardPagePtr}--;
	$self->{wizardPagePtr} = 0 if( $self->{wizardPagePtr} < 0);
	$self->{nextButton}->configure( -text => $LABELS{NEXT});
	$self->{backButton}->configure( -state => "disabled") if( $self->{wizardPagePtr} == 0);
	$self->render_current_page;
	if( dispatch( $self->cget(-postBackButtonAction))) { return; }
}

sub HelpButtonEventCycle { my $self = shift;
	if (dispatch( $self->cget(-preHelpButtonAction))) { return; }
	if (dispatch( $self->cget(-helpButtonAction))) { return; }
	if (dispatch( $self->cget(-postHelpButtonAction))) { return; }
}


sub CancelButtonEventCycle { my ($self, $args) = (shift, @_);
	return if $self->Callback( -preCancelButtonAction => $self->{-preCancelButtonAction} );
	$self->CloseWindowEventCycle( $args);
}


sub CloseWindowEventCycle { my ($self, $hGUI) = (shift,@_);
	return if $self->Callback( -preCloseWindowAction => $self->{-preCloseWindowAction} );
	$self->destroy;
#	return if dispatch( $self->cget(-preCloseWindowAction));
#	$hGUI->destroy;
}



=head2 METHOD addDirSelectPage

	$wizard->addDirSelectPage ( -variable => \$chosen_dir )

Adds a page (C<Tk::Frame>) that contains a scrollable texxt box of all
directories including, on Win32, logical drives.

Supply in C<-variable> a reference to a variable to set the initial
directory, and to have set with the chosen path.

Supply C<-nowarnings> with a value of C<1> to list only drives which are
accessible, thus avoiding C<Tk::DirTree> warnings on Win32 where removable
drives have no media. Supply C<-nowarnings> with any other
value to avoid listing drives which are both inacessible and - on Win32 - are
either fixed drives, network drives, or RAM drives (that is types 3, 4, and
6, according to C<Win32API::File::GetDriveType>.

You may also specify the C<-title>, C<-subtitle> and C<-text> paramters, as
in L<METHOD blank_frame>.

See L<CALLBACK callback_dirSelect>.

=cut

sub addDirSelectPage { my ($self,$args) = (shift,{@_});
	$self->addPage( sub { $self->page_dirSelect($args)  } );
}

#
# PRIVATE METHOD page_dirSelect
#
# It'd be nice to use FBox here, but it doesn't seem to support dir selection
# and DirSelect is broken and ugly
#
# As blank_frame plus:
# -variable => Reference to a variable to set.
# -nowarnings => 1 : chdir to each drive first and only list if accessible
#             => >1: as 1, plus on types 3,4 and 6.
#
sub page_dirSelect { my ($self,$args) = (shift,shift);
	if (not $args->{-variable}){
		croak "You must supply a -varialbe paramter";
	} elsif (not ref $args->{-variable}){
		croak "The -variable parameter must be a reference";
	}
	my $_drives = sub {
		return '/' if $^O !~ /MSWin32/i;
		eval('require Win32API::File');
		return Win32API::File::getLogicalDrives();
	};
	my ($frame,@pl) = $self->blank_frame(
		-title => $args->{-title} || "Please choose a directory",
		-subtitle => $args->{-subtitle}  || "After you have made your choice, press Next to continue.",
		-text => $args->{-text} || "",
	);
	$frame->Frame(-height=>10)->pack();
	my $entry	= $frame->Entry(
		-justify		=> 'left',
		-width			=> 40,
		-textvariable	=> $args->{-variable},
	)->pack(-side=>'top',-anchor=>'w',-fill=>"x", -padx=>10, -pady=>10,);
	$entry->configure(-background=>$self->cget("-background")) if $self->cget("-background");
	my $dirs	= $frame->Scrolled ( "DirTree",
		-scrollbars => 'osoe',
		-selectbackground => "navy", -selectforeground => "white",-selectmode =>'browse',
		-width=>40, height=>10,
		-browsecmd => sub { ${$args->{-variable}}=shift },
	)->pack(-fill=>"x",-padx=>10, -pady=>0,);
	$dirs->configure(-background=>$self->cget("-background")) if $self->cget("-background");
	$frame->Frame(-height=>10)->pack();

	my $mkdir = $frame->Button( -text => "New Directory",
		-command => sub {
			my $new_name = $self->prompt(-title=>'Create New Directory',-text=>"Please enter the name for the new directory");
			if ($new_name){
				$new_name =~ s/[\/\\]//g;
				$new_name = ${$args->{-variable}} ."/$new_name";
				if (! mkdir $new_name,0777){
					if ($! =~ /Invalid argument/i){
						$_ = "The directory name you supplied is not valid.";
					} elsif ($! =~ /File Exists/i){
						$_ = "A directory with that name already exists.";
					} else {
						$_ = "The directory could not be created:\n\n\t'$!'"
					}
					$self->parent->messageBox(
						'-icon' => 'error', -type => 'ok',-title => 'Could Not Create Directory',
						-message => $_,
					);
				} else {
					${$args->{-variable}} = $new_name;
					$dirs->configure(-directory => $new_name);
					$dirs->chdir($new_name);
				}
			}
		}, # end of -command sub
	)->pack( -side => 'right', -anchor => 'w', -padx=>'10', );
	if ($self->{desktop_dir}){ # Thanks, Slaven Rezic.
		$frame->Button( -text => "Desktop",
			command => sub {
				${$args->{-variable}} = "$ENV{USERPROFILE}/Desktop";
				$dirs->configure(-directory => "$ENV{USERPROFILE}/Desktop");
				$dirs->chdir("$ENV{USERPROFILE}/Desktop");
			},
		)->pack( -side => 'right', -anchor => 'w', -padx=>'10', );
	}
	foreach (&$_drives){
		($_) =~ /^(\w+:)/;
		if ($args->{-nowarnings} and ($args->{-nowarnings} eq "1"
		or $^O !~ /MSWin32/i)){
			$dirs->configure(-directory=>$_) if chdir  $_;
		} elsif ($args->{-nowarnings}){
			if ($DRIVETYPES{Win32API::File::GetDriveType($_)}
			and chdir  $_){
				$dirs->configure(-directory=>$_);
			}
		} else {
			$dirs->configure(-directory=>$_);
		}
	}
	return $frame;
}


=head2 CALLBACK callback_dirSelect

A callback to check that the directory, passed as a reference in the sole
argument, exists, and can and should be created.

Will not allow the Wizard to continue unless a directory has been chosen.
If the chosen directory does not exist, Setup will ask if it should create
it. If the user affirms, it is created; otherwise the user is again asked to
chose a directory.

Returns a Boolean value.

This method relies on C<Win32API::File> on MS Win32 machines only.

=cut

sub callback_dirSelect { my ($self,$var) = (shift,shift);
	if (not $$var){
		$self->parent->messageBox(
			'-icon' => 'info', -type => 'ok',-title => 'Form Incomplete',
			-message => "Please select a directory to continue."
		);
	}
	elsif (!-d $$var){
		$$var =~ s|[\\]+|/|g;
		$$var =~ s|/$||g;
		my $button = $self->parent->messageBox(
			-icon => 'info', -type => 'yesno',
			-title => 'Directory does not exist',
			-message => "The directory you selected does not exist.\n\n"."Shall I create ".$$var." ?"
		);
		if (lc $button eq 'yes'){
			return 1 if File::Path::mkpath( $$var);
			$self->parent->messageBox(
				-icon => 'warning', -type => 'ok',
				-title => 'Directory Could Not Be Created',
				-message => "The directory you entered could not be created.\n\nPlease enter a different directory and press Next to continue."
			);
		} else {
			$self->parent->messageBox(
				-icon => 'info', -type => 'ok',
				-title => 'Directory Required',
				-message => "Please select a directory so that Setup can install the software on your machine.",
			);
		}
	} else {
		return 1;
	}
	return 0;
}


=head2 METHOD addTaskListPage

Adds a page to the Wizard that will perform a series of tasks, keeping the user
informed by ticking-off a list as each task is accomplished.

Whilst the task list is being executed, both the I<Back> and I<Next> buttons
are disabled.

Paramters are as for C<blank_frame> (see L<METHOD blank_frame>), plus:

=over 4

=item -tasks

The tasks to perform, supplied as a reference to an array, where each entry is a pair (ie a two-member list),
the first of which is a text string to display, the second a reference to code to execute.

=item -delay

The length of the  delay, in milliseconds, after the page has been displayed and
before execution the task list is begun. See L<the entry for the 'after' routine in the Tk::After manpage|Tk::After>.

=item -continue

Display the next Wizard page once the job is done: invokes the callback
of the I<Next> button at the end of the task.

=item -todo_photo

=item -done_photo

Optional: both C<Tk::Photo> objects, the former displayed before an item on the taks list has been executed,
which is changed to the latter after completion of the item. If not provided, then not displayed.

If I knew more about TK bitmaps, or any bitmaps other than Vic-20, I'd extend this to have defaults.

=item -label_frame_title

The label above the C<Tk::LabFrame> object which
contains the task list. Default label is the boring C<Performing Tasks:>.

=item -frame_args

Optional: the arguments to pass in the creation of the C<Frame> object used to contain the list.

=item -frame_pack

Optional: array-refernce to pass to the C<pack> method of the C<Frame> containing the list.

=back

=head 2 TASK LIST EXAMPLE

	$wizard->addTaskListPage(
		-title => "Toy example",
		-tasks => [
			"Wait five seconds" => sub { warn "waiting for 5 ...."; sleep 5;  print "ok 8\n"},
			"Wait ten seconds!" => sub { warn "waiting for 10...."; sleep 10; print "ok 9\n"},
		],
	);

=cut

sub addTaskListPage { my ($self,$args) = (shift,{@_});
	$self->addPage( sub { $self->page_taskList($args)  } );
}


=head2 METHOD page_taskList

The same as C<addTaskListPage> (see L<METHOD addTaskListPage>)
but does not add the page to the Wizard.

Note that unlink C<addTaskListPage>, arguments are expected in a hash reference.

Useful for a task list that cannot be filled before the call
to C<Show()>.

Parameter C<-label_frame_title> is the label above the C<Tk::LabFrame> object which
contains the task list. Default label is the boring C<Performing Tasks:>.

=cut

sub page_taskList { my ($self,$args) = (shift,shift);
	my @tasks;
	if (not $args->{-todo_photo}){
		warn "No -todo_photo" if $^W;
	} elsif  (!-r $args->{-todo_photo}
		or not $self->Photo( "todo", -file => $args->{-todo_photo})){
		warn "Could not read -todo_photo at $args->{-todo_photo}" if $^W;
		undef $args->{-todo_photo};
	}
	if (not $args->{-done_photo}){
		warn "No -done_photo" if $^W;
	} elsif (!-r $args->{-done_photo}
	or !$self->Photo( "done", -file => $args->{-done_photo})){
		warn "Could not read $args->{-done_photo}" if $^W;
		undef $args->{-done_photo};
	}
	$args->{-frame_pack} = [
		qw/-expand 1 -fill x -padx 40 -pady 10/
	] unless $args->{-frame_pack};
	$args->{-frame_args} = [
		-relief=>"flat",-bd=>0,
		-label => $args->{-label_frame_title} || "Performing Tasks: ",
		-labelside => "acrosstop"
	] unless $args->{-frame_args};

	my $frame = $self->blank_frame(
		-title => $args->{-title} || "Performing Taks",
		-subtitle => $args->{-subtitle}  || "Please wait whilst the Wizard performs these tasks.",
		-text => $args->{-text}  || "",
	);
	if ($#{$args->{-tasks}}>-1){
		my $task_frame = $frame->LabFrame(
			@{$args->{-frame_args}}
		)->pack(
			@{$args->{-frame_pack}}
		);

		foreach ( my $i=0; $i<=$#{$args->{-tasks}}; $i+=2 ){
			my $icn="-1";
			$_ = $task_frame->Frame()->pack(-side=>'top',-anchor=>"w");
			if (defined $args->{-todo_photo}){
				$icn = $_->Label(-image=>"todo",-anchor=>"w")->pack(-side=>"left");
			}
			$_->Label(-text=>@{$args->{-tasks}}[$i],-anchor=>"w")->pack(-side=>"left");
			push @tasks, [$icn,@{$args->{-tasks}}[$i+1]];
		}
	} else {
		$args->{-delay} = 1;
	}
	$self->{nextButton}->configure(-state=>"disabled");
	$self->{backButton}->configure(-state=>"disabled");
	$frame->after( $args->{-delay} || 1000, sub {
		foreach my $task (@tasks){
			&{@$task[1]};
			if (ref @$task[0]){
				@$task[0]->configure(-image=>"done")
			}
			$self->update;
		}
		$self->{nextButton}->configure(-state=>"normal");
		$self->{backButton}->configure(-state=>"normal");
		$self->{nextButton}->invoke if $args->{-continue};
	});
	return $frame;
}



=head1 METHOD addMultipleChoicePage

Allow the user to make multiple choices between choose options:
each choice sets a variable passed as reference to this method.

Accepts the usual paramters plus:

=over 4

=item -relief

For the radio buttons - see L<Tk::options>.

=item -choices

A reference to an array of  hashes with the following fields:

=over 4

=item -title

Title of the option, rendered in bold

=item -subtitle

Text rendered smaller beneath the C<-title> field's value.

=item -variable

Reference to a variable that will contain the result of the choice.
Croaks if none supplied.

=item -checked

Contains a true value to specify the box should initially
appear checked.

=back

=back

Support for images by the radio buttons would be good.

=cut

sub addMultipleChoicePage { my ($self,$args) = (shift,{@_});
	return $self->addPage( sub { $self->page_multiple_choice($args)  } );
}

sub page_multiple_choice { my ($self,$args) = (shift,shift);
	my $frame = $self->blank_frame(%$args);

	croak "-chocies should be a ref to an array!" if not $args->{-choices} or not ref $args->{-choices} or ref $args->{-choices} ne 'ARRAY';

	my $content = $frame->Frame()->pack(-side=>'top',-anchor=>"n",-padx=>30,-pady=>10,);

	foreach my $opt (@{$args->{-choices}}){
		croak "Option in -choices array is not a hash!" if not ref $opt or ref $opt ne 'HASH';
		croak "No -varialbe!" if not $opt->{-variable};
		croak "-varialbe should be a reference!" if not ref $opt->{-variable};
		my $b = $content->Checkbutton(
			-text		=> $opt->{-title},
			-justify	=> 'left',
			-relief		=> $args->{-reflief}||'flat',
			-font		=> "RADIO_BOLD",
			-variable	=> $opt->{-variable},

		)->pack(qw/-side top -anchor w /);
		$b->invoke if defined $opt->{-checked};
		if (defined $opt->{-subtitle}){
			$content->Label(
				-text	=> $opt->{-subtitle},
			)->pack(qw/-side top -anchor w -padx 25 -pady 0/);
		}
	}
	return $frame;
}


# Returns true if to continue
# By default, may be called by close window or pressing cancel
sub DIALOGUE_really_quit { my $self = shift;
	return 0 if $self->{nextButton}->cget(-text) eq $LABELS{FINISH};
	unless ($self->{really_quit}){
		my $button = $self->parent->messageBox('-icon' => 'question', -type => 'yesno',
		-default => 'no', -title => 'Quit Setup?',
		-message => "Setup has not finished installing.\n\nIf you quit now, you will not be able to run the software.\n\nDo you really wish to quit?");
		$self->{really_quit} = lc $button eq 'yes'? 1:0;
	}
	return !$self->{really_quit};
}


=head2 DIALOGUE METHOD prompt

Equivalent to the JavaScript method of the same name: pops up
a dialogue box to get a text string, and returns it.  Arguemnts
are:

=over 4

=item -parent =>

C<Tk> object that is our parent window. Default's to our C<parent> field.

=item -title =>

The title of the dialogue box.

=item -text =>

The text to display above the C<Entry> widget.

=item -value =>

The initial value of the C<Entry> box.

=item -wraplength =>

Text C<Label>'s wraplength: defaults to 275.

=item -width =>

The C<Entry> widget's width: defaults to 40.
=back

=cut

sub prompt { my ($self,$args) = (shift,{@_});
	eval ('use Tk::DialogBox');
	my ($d, $w);
	my $input = $self->cget(-value);
	$args->{-parent} = $self->parent if not $args->{-parent};
	$d = $args->{-parent}->DialogBox(-title => $args->{-title}||"Prompt",
		-buttons => [$LABELS{CANCEL},$LABELS{OK}],-default_button=>$LABELS{OK},
	);
	if ($args->{-text}){
		$w = $d->add("Label",
			-font => $self->{defaultFont},
			-text => $args->{-text},
			-width=>40, -wraplength => $args->{-wraplength}||275,
			-justify => 'left', -anchor=>'w',
		)->pack();
	}
	$w = $d->add("Entry",
		-font => $self->{defaultFont}, -relief=>"sunken",
		-width => $args->{-width}||40,
		-background => "white",
		-justify => 'left',
		-textvariable => \$input,
	);
	$w->pack(-padx=>2,-pady=>2);
	$d->Show;
	return $input? $input : undef;
}



1;

=head1 ACTION EVENT HANDLERS

A Wizard is a series of pages that gather information and perform tasks based upon
that information. Navigated through the pages is via I<Back> and I<Next> buttons,
as well as I<Help>, I<Cancel> and I<Finish> buttons.

In the C<Tk::Wizard> implimentation, each button has associated with it one or more
action event handlers, supplied as code-references executed before, during and/or
after the button press.

The handler code should return a Boolean value, signifying whether the remainder of
the action should continue. If a false value is returned, execution of the event
handler halts.

=over 4

=item -preNextButtonAction =>

This is a reference to a function that will be dispatched before the Next
button is processed.

=item -postNextButtonAction =>

This is a reference to a function that will be dispatched after the Next
button is processed.

=item -preBackButtonAction =>

This is a reference to a function that will be dispatched before the Previous
button is processed.

=item -postBackButtonAction =>

This is a reference to a function that will be dispatched after the Previous
button is processed.

=item -preHelpButtonAction =>

This is a reference to a function that will be dispatched before the Help
button is processed.

=item -helpButtonAction =>

This is a reference to a function that will be dispatched to handle the Help
button action.

=item -postHelpButtonAction =>

This is a reference to a function that will be dispatched after the Help
button is processed.

=item -finishButtonAction =>

This is a reference to a funciton that will be dispatched to handle the Finish
button action.

=item -postFinishButtonAction =>

This is a reference to a function that will be dispatched after the Finish
button is processed.

=item -preCancelButtonAction =>

This is a reference to a function that will be dispatched before the Cancel
button is processed.  Default is to exit on user confirmation - see
L<METHOD DIALOGUE_really_quit>.

=item -preCloseWindowAction =>

This is a reference to a funciton that will be dispatched before the window
is issued a close command. Default is to exit on user confirmation - see
L<DIALOGUE METHOD DIALOGUE_really_quit>.

=back

All active event handlers can be set at construction or using C<configure> -
see L<WIDGET-SPECIFIC OPTIONS> and L<METHOD configure>.

=head1 BUTTONS

	backButton nextButton helpButton cancelButton

If you must, you can access the Wizard's button through the object fields listed
above, each of which represents a C<Tk::BUtton> object. Yes, this is not a good
way to do it: patches always welcome ;)

This is not advised for anything other than disabling or re-enabling the display
status of the buttons, as the C<-command> switch is used by the Wizard:

	$wizard->{backButton}->configure( -state => "disabled" )

Note: the I<Finish> button is simply the C<nextButton> with the label C<$LABEL{FINISH}>.

See also L<INTERNATIONALISATION>.

=head1 INTERNATIONALISATION

The labels of the buttons can be changed (perhaps into a language other an English)
by changing the values of the package-global C<%LABELS> hash, where keys are
C<BACK>, C<NEXT>, C<CANCEL>, C<HELP>, and C<FINISH>.

The text of the callbacks can also be changed via the
C<%LABELS> hash: see the top of the source code for details.

=head1 IMPLIMENTATION NOTES

This widget is implimented using the Tk 'standard' API as far as possible,
given my almost three weeks of exposure to Tk. Please, if you have a suggestion,
or patch, send it to me directly: C<LGoddard@CPAN.org>.

The widget is a C<MainWindow> and not a C<TopLevel> window. The reasoning is that
Wizards are applications in their own right, and not usually parts of other
applications. Although at the time of writing, I had only three weeks of Tk, I believe
it should be possible
to embed a C<Tk::Wizard> into another window using C<-use> and C<-container> -- but
any info on this practice would be appreciated.

There is one outstanding bug which came about when this Wizard was translated
from an even more naive implimentation to the more-standard manner. That is:
because C<Wizard> is a sub-class of C<MainWIndow>, the C<-background> is inacessible
to me. Advice and/or patches suggestions much appreciated.

=head2 THE Tk::Wizard NAMESPACE

In discussion on comp.lang.perl.tk, it was suggested by Dominique Dumont
(would you mind your address appearing here?) that the following guidelines
for the use of the C<Tk::Wizard> namespace be followed:

=over 4

=item 1

That the module C<Tk::Wizard> act as a base module, providing all the basic services and
components a Wizard might require.

=item 2

That modules beneath the base in the hierachy provide implimentations based on
aesthetics and/or architecture.

=back

=head1 NOTES ON SUB-CLASSING Tk::Wizard

If you are planning to sub-class C<Tk::Wizard> to create a different display style,
there are three routines you will need to over-ride:

=over 4

=item initial_layout

=item render_current_page

=item blank_frame

=back

This may change, please bear with me.

=head1 CAVEATS / BUGS / TODO

=over 4

=item *

20 January 2003: the directory tree part does not create directories
unless the eponymous button is clicked.

=item *

In Windows, with the system font set to > 96 dpi (via Display Properties / Settings
/ Advanced / General / Display / Font Size), the Wizard will not display propertly.
This seems to be a Tk feature.

=item *

Still not much of a Tk widget inheritance - any pointers welcome.

=item *

Nothing is currently done to ensure text fits into the window - it is currently up to
the client to make frames C<Scrolled>), as I'm having problems making C<&blank_frame>
produce them.

=back

=head1 CHANGES

Please see the file F<CHANGES.txt> included with the distribution.

=head1 AUTHOR

Lee Goddard (lgoddard@cpan.org) based on work Daniel T Hable.

=head1 KEYWORDS

Wizard; set-up; setup; installer; uninstaller; install; uninstall; Tk; GUI.

=head1 COPYRIGHT

Copyright (c) Daniel T Hable, 2/2002.

Modifications Copyright (C) Lee Goddard, 11/2002 - 01/2003.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of
the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

THIS SOFTWARE AND THE AUTHORS OF THIS SOFTWARE ARE IN NO WAY CONNECTED TO THE MICROSOFT CORP.

THIS SOFTWARE IS NOT ENDORSED BY THE MICROSOFT CORP

MICROSOFT IS A REGISTERED TRADEMARK OF MICROSOFT CROP.


=cut




__END__
