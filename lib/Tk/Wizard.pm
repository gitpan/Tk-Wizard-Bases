package Tk::Wizard;
$Tk::Wizard::DEBUG = undef;
our
# $VERSION = do { my @r = (q$Revision: 1.951 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
$VERSION = '1.951'; # Martin Thurn's interim release

=head1 NAME

Tk::Wizard - GUI for step-by-step interactive logical process

=cut

use lib '../';
use Carp;
use Config;
use Cwd;
use Tk;
use Tk::DirTree;
use Tk::Wizard::Image;
use File::Path;
use Tk::ROText;
use Tk::MainWindow;
use Tk::Frame;

BEGIN {
	require Exporter;	   		# Exporting Tk's MainLoop so that
	@ISA = ( "Exporter",);	   # I can just use strict and Tk::Wizard without
	@EXPORT = ("MainLoop");   # having to use Tk
}

our $DEFAULT_WIDTH  = 550;  # 400
our $DEFAULT_HEIGHT = 360;  # 316

#use base  qw(Tk::MainWindow);
use base qw[Tk::Derived Tk::Toplevel ];
Tk::Widget->Construct('Wizard');

use strict;
if ($^V and $^V gt v5.8.0){
	eval "use warnings";
}

use vars qw/%LABELS/;

# See INTERNATIONALISATION
%LABELS = (
	# Buttons
	BACK => "< Back",	NEXT => "Next >",
	FINISH => "Finish",	CANCEL => "Cancel",
	HELP => "Help",		OK => "OK",
);

=head1 SYNOPSIS

	use Tk::Wizard;
	my $wizard = new Tk::Wizard;
	#
	# OR
	# my $MW = Tk::MainWindow->new;
	# my $wizard = $MW->Wizard();
	#
	$wizard->configure( -property=>'value');
	$wizard->cget( "-property");
	$wizard->addPage(
		... code-ref to anything returning a Tk::Frame ...
	);
	$wizard->addPage( sub {
		return $wizard->blank_frame(
			-title	  => "Page Title",
			-subtitle => "Sub-title",
			-text	  => "Some text.",
			-wait	  => $seconds_b4_proceeding_anyway,
		);
	});
	$wizard->Show;
	MainLoop;
	exit;

To avoid 50 lines of SYNOPSIS, please see the files included with the
distribution in the test directory: F<t/*.t>.  These are just Perl
files that are run during the C<make test> phase of installation: you
may rename them without harm once you have installed the module.

=head1 CHANGES

The widget now works from within a C<MainWindow>, or creates its own as necessary for backwards compatability.

The optoin C<-image_dir> has been deprecated, and the once-used binary
images have been dropped from the distribution in favour of Base64-
encoded images. More and other details in F<ChangeLog>.

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
simillar to that found in Windows 2000, though the more traditional Windows 95-like feel is also
supported (see the C<-style> entry in L<WIDGET-SPECIFIC OPTIONS>. Sub-classing the
module to provide different look-and-feel is highly encourage: please see
L<NOTES ON SUB-CLASSING Tk::Wizard>. If anyone would like to do a I<Darwin> or
I<Aqua> version, please let me know how you would like to handle the buttons. I'm not
hot on advertising widgets.

NB: B<THIS IS STILL AN ALPHA RELEASE: ALL CONTRIBUTIONS ARE WELCOME!>

Please read L<CAVEATS, BUGS, TODO>.

=head1 ADVERTISED SUB-WIDGETS

Still untested. Use:

	$wizard->Subwidget('buttonpanel');

=over 4

=item buttonPanel

The C<Frame> that holds the navigation buttons and optional help button.

=item nextButton

=item backButton

=item cancelButton

=item helpButton

The buttons in the C<buttonPanel>.

=item tagLine

The line above the C<buttonpanel>

=item tagText

The grayed-out text above the C<buttonpanel>.

=item tagBox

The frame holding the tag text.

=item imagePane

Either the image on the first and last pages. Also: for C<95> C<style> wizards: the same;
for C<style> C<top> (default) Wizards, the box at the top of the wizard. What a terrible sentance.

=item wizardFrame

The frame that holds the content frame.

=back

=head1 STANDARD OPTIONS

=over 4

=item -title

Text that appears in the title bar.

=item -background

Main background colour of the Wizard's window.

=item -width -height

Size of the wizard. This is adjustable per-page - every method that adds a page will accept these options and pass them on to the main Wizard window.

=back

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item Name:   style

=item Class:  Style

=item Switch: -style

Sets the display style of the Wizard.

The default no-value or value of C<top> gives the Wizard will be a Windows 2000-like
look, with the initial page being a white-backgrounded version of the traditional
style, and subsequent pages being C<SystemButtonFace> coloured, with a white
strip at the top holding a title and subtitle, and a smaller image (see
C<-topimagepath>, below).

The old default of C<95> is still available, if you wish to create a traditional,
Windows 95-style wizard, with every page being C<SystemButtonFace> coloured, with a
large image on the left (C<-imagepath>, below).

=item Name:   imagepath

=item Class:  Imagepath

=item Switch: -imagepath

Path to an image that will be displayed on the left-hand side
of the screen.  (Dimensions are not constrained.) One of either:

=over 4

=item *

Path to a file from which to construct a L<Tk::Photo|Tk::Photo>
object without the format being specified;
No checking is done, but paths ought to be absolute, as no effort
is made to maintain or restore any initial current working directory.

=item *

Base64-encoded images to pass in the C<-data> field of the
L<Tk::Photo|Tk::Photo> object. This is the default form, and a couple
of unused images are supplied: see L<Tk::Wizard::Image>.

=back

=item Name:   topimagepath

=item Class:  Topimagepath

=item Switch: -topimagepath

Only required if C<-style=E<gt>'top'> (as above): the image
this filepath specifies
will be displayed in the top-right corner of the screen. Dimensions are not
restrained (yet), but only 50x50 has been tested.

Please see notes for the C<-imagepath>>.

=item Name:   nohelpbutton

=item Class:  Nohelpbutton

=item Switch: -nohelpbutton

Set to anything to disable the display of the I<Help> buton.

=item Name:   resizable

=item Class:  resizable

=item Switch: -resizable

Supply a boolean value to allow resizing of the window: default
is to disable that feature to minimise display issues.

=item Switch: -tag_text

Text to supply in a 'tag line' above the wizard's control buttons.

=item Switch: -tag_width

Width for C<-tag_text>, above: when I work out better C<pack>ing,
this will no longer be needed.
Default value is based on the length of your -tag_text.

=item Switch: -tag_disable

Disables display of the C<-tag_text>, above.

=item -image_dir

Deprecated. Supply C<-imagepath> and/or C<-topimagepath>.

=back

Please see also L<ACTION EVENT HANDLERS>.

=cut


# The method is overridden to allow us to supply a MainWindow if one is
# not supplied by the caller. Not supplying one suits me, but Mr Rothenberg requires one.
sub new {
	my $inv = ref($_[0])? ref($_[0]) : $_[0];
	shift;
	my @args = @_;
	unless (scalar(@_) % 2		# not a simple list
	and ref $args[0]){  # assume ref is to mainwindow
		# Get a main window
		unshift @args, Tk::MainWindow->new;
		push @args, "-parent" => $args[0];
		push @args, "-kill_parent_on_destroy" => 1;
		$args[0]->optionAdd('*BorderWidth' => 1);
	}

	return $inv->SUPER::new(@args);
}


#sub ClassInit {
#	my( $class, $mw ) = @_;
#	$class->SUPER::ClassInit( $mw );
#}


sub Populate { my ($self, $args) = @_;
	warn "# Enter Populate" if $self->{-debug};

    $self->SUPER::Populate($args);

	my $sFontFamily = &_font_family();
	my $iFontSize = &_font_size();
	my $sTagTextDefault = 'Perl Wizard';
	my $iTagWidthDefault = $iFontSize * length($sTagTextDefault) / 1.5;

	# $composite->ConfigSpecs(-attribute => [where,dbName,dbClass,default]);

    $self->ConfigSpecs(
#		-title			=> ['SELF','title','Title','Generic Wizard'],
# ?		-resizable		=> ['SELF','resizable','Resizable',undef],
		-resizable		=> ['SELF','resizable','Resizable',undef],
#		-foreground 	=> ['PASSIVE', 'foreground','Foreground', 'black'],

		-parent			=> ['PASSIVE', undef,undef,undef], # potentially a mainwindow
		-title			=> ['PASSIVE', undef,undef,'Generic Wizard'],

		-command    	=> ['CALLBACK', undef, undef, undef ],
		-background 	=> ['METHOD', 'background','Background',
		$^O=~/(MSWin32|cygwin)/i? 'SystemButtonFace':undef],
		-style			=> ['PASSIVE',"style","Style","top"],
		-imagepath		=> ['PASSIVE','imagepath', 'Imagepath', \$Tk::Wizard::Image::LEFT{WizModernImage}],
		-topimagepath	=> ['PASSIVE','topimagepath', 'Topimagepath', \$Tk::Wizard::Image::TOP{WizModernSmallImage}],
		# event handling references
		-nohelpbutton			=> ['CALLBACK',undef,undef, sub {1} ],
		-preNextButtonAction    => ['CALLBACK',undef,undef, sub {1} ],
		-postNextButtonAction   => ['CALLBACK',undef,undef, sub {1} ],
		-preBackButtonAction    => ['CALLBACK',undef,undef, sub {1} ],
		-postBackButtonAction   => ['CALLBACK',undef,undef, sub {1} ],
		-preHelpButtonAction    => ['CALLBACK',undef,undef, sub {1} ],
		-helpButtonAction       => ['CALLBACK',undef,undef, sub {1} ],
		-postHelpButtonAction   => ['CALLBACK',undef,undef, sub {1} ],
		-preFinishButtonAction	=> ['CALLBACK',undef,undef, sub {1} ],
		-finishButtonAction     => ['CALLBACK',undef,undef, sub { $self->destroy; 1 } ],
		-kill_parent_on_destroy	=> ['PASSIVE', undef, undef, undef ],
		-debug                  => ['PASSIVE',undef,undef,undef],
                # -finishButtonAction     => ['CALLBACK',undef,undef, sub {1} ],
		-preCloseWindowAction	=> ['CALLBACK',undef,undef, sub { &DIALOGUE_really_quit($self); }],
		-tag_text				=> ['PASSIVE', "tag_text", "TagText", $sTagTextDefault],
		-tag_width				=> ['PASSIVE', "tag_width", "TagWidth", $iTagWidthDefault],
		-width  				=> ['SELF', 'width', 'Width', $DEFAULT_WIDTH ],
		-height 				=> ['SELF', "height", "Height", $DEFAULT_HEIGHT ],
		-wizardFrame 			=> ['PASSIVE', undef, undef, 0 ],
	);

# 		-width  => [$self->{-style} eq 'top'? 500 : 570) unless $args->{-width};
	# $self->{wizardFrame}	= 0;


	if (exists $args->{-imagepath} and not -e $args->{-imagepath}){
		confess "Can't find file at -imagepath: ".$args->{-imagepath};
	}
	if (exists $args->{-topimagepath} and not -e $args->{-topimagepath}){
		confess "Can't find file at -topimagepath: ".$args->{-topimagepath};
	}
	$self->{-imagepath}		= $args->{-imagepath};
	$self->{-topimagepath}	= $args->{-topimagepath};


	$self->{wizardPageList}	= [];
	$self->{wizardPagePtr}	= 0;
	$self->{-debug}			= $args->{-debug} || $Tk::Wizard::DEBUG|| undef;
	$self->{background_userchoice} = $args->{-background} || $self->ConfigSpecs->{-background}[3];
	$self->{background} 	= $self->{background_userchoice};

	$self->{-style}  = $args->{-style} || "top";

	# $self->overrideredirect(1); # Removes borders and controls

	{
		my $buttonPanel = $self->Frame;
		# right margin
		$buttonPanel->Frame(-width=>10)->pack( -side => "right", -expand => 0,-pady=>10);
		# Bottom
		$self->{cancelButton} = $buttonPanel->Button( -text => $LABELS{CANCEL},
			-command => [ \&CancelButtonEventCycle, $self, $self],-width => 10,
		) ->pack( -side => "right", -expand => 0,-pady=>10);
		$buttonPanel->Frame(-width=>10)->pack( -side => "right", -expand => 0,-pady=>10);
		$self->{nextButton} = $buttonPanel->Button( -text => $LABELS{NEXT},
			-command => [ \&NextButtonEventCycle, $self ],
			-width => 10
		)->pack( -side => "right", -expand => 0,-pady=>10);
		$self->{backButton} = $buttonPanel->Button( -text => $LABELS{BACK},
			-command => [ \&BackButtonEventCycle, $self ],
			-width => 10,
			-state => "disabled"
		)->pack( -side => "right", -expand => 0,-pady=>10);
		if ($self->cget(-nohelpbutton)){
			$self->{helpButton} = $buttonPanel->Button( -text => $LABELS{HELP},
				-command => [ \&HelpButtonEventCycle, $self ],
				-width => 10,
			)->pack( -side => 'left', -anchor => 'w',-pady=>10,-padx=>10);
			$self->Advertise( helpButton => $self->{helpButton} );
		}
		$buttonPanel->pack(qw/ -side bottom -fill x/);

		$self->Advertise( nextButton => $self->{nextButton} );
		$self->Advertise( backButton => $self->{backButton} );
		$self->Advertise( cancelButton => $self->{cancelButton} );

		$self->Advertise( buttonPanel => $buttonPanel );
	}


	# Tag text
	$args->{-tag_text} = $sTagTextDefault unless exists $args->{-tag_text};
	$iTagWidthDefault = $iFontSize * length($args->{-tag_text}) / 1.5;
	$args->{-tag_width} = $iTagWidthDefault unless exists $args->{-tag_width};
	# Container for line/tag
	{
		my $tagbox = $self->Frame(
			-width => $self->cget(-width)-($args->{-tag_width} || $iTagWidthDefault) || $DEFAULT_WIDTH,
	#		-background=>$self->cget(-background),
			-height => 12,
		)->pack(qw/-side bottom -fill x/);

		$self->fontCreate('TAG',
			-family => $sFontFamily,
			-size => $iFontSize,
			-weight => 'bold',
		);
		$self->{tagtext} = $tagbox->Canvas(
			-relief => 'flat',
			-border => 1,
			-height => $iFontSize * 1.5,
			-width => $args->{-tag_width},
		)->pack(-side=>'left', -anchor=>'e');
		$self->{tagtext}->createText(4,7,-text=>$args->{-tag_text},-fill=>'#999999',-anchor=>'w',-font=>'TAG',);
		$self->{tagtext}->createText(4,9,-text=>$args->{-tag_text},-fill=>'white',-anchor=>'w',-font=>'TAG',);
		$self->{tagtext}->createText(4,8,-text=>$args->{-tag_text},-fill=>'gray',-anchor=>'w',-font=>'TAG',);

		# This is the line above buttons:
		$self->{tagline} = $tagbox->Frame(
			-width => $self->cget(-width) || $DEFAULT_WIDTH,
			-background=>$self->cget(-background),
			qw/ -relief groove -bd 1 -height 2/,
		)->pack(-side=>'left', -anchor=>'e');

		$self->Advertise( tagLine => $self->{tagline} );
		$self->Advertise( tagBox  => $tagbox );
		$self->Advertise( tagText => $self->{tagtext} );
	}

	# Desktops for dir select: thanks to Slaven Rezic who also suggested SHGetSpecialFolderLocation for Win32. l8r
	# There is a module for this now
	if ($^O =~ /win/i and -d "$ENV{USERPROFILE}/Desktop"){
		# use OLE;
		$self->{desktop_dir} = "$ENV{USERPROFILE}/Desktop"
	} elsif (-d "$ENV{HOME}/Desktop"){
		$self->{desktop_dir} = "$ENV{HOME}/Desktop";
	} elsif (-d "$ENV{HOME}/.gnome-desktop"){
		$self->{desktop_dir} = "$ENV{HOME}/.gnome-desktop";
	}

	# Font used for &blank_frame titles
	$self->fontCreate('TITLE_FONT', -family => $sFontFamily, -size => $iFontSize*1.5, -weight => 'bold');
	# Font used in multiple choices for radio title
	$self->fontCreate('RADIO_BOLD', -family => $sFontFamily, -size => $iFontSize, -weight => 'demi');
	# Fonts used if -style=>"top"
	$self->fontCreate('TITLE_FONT_TOP', -family => $sFontFamily, -size => $iFontSize, -weight => 'bold');
	$self->fontCreate('SUBTITLE_FONT', -family => $sFontFamily, -size => $iFontSize);
	# Font used in licence agreement	XXX REMOVE TO CORRECT MODULE
	$self->fontCreate('SMALL_FONT', -family => $sFontFamily, -size => $iFontSize);
	# Font used in all other places
	$self->fontCreate('DEFAULT_FONT', -family => $sFontFamily, -size => $iFontSize);
	$self->{defaultFont} = 'DEFAULT_FONT';

}


# Private method: returns a font family name suitable for the operating system.
sub _font_family {
	return 'verdana' if ($^O =~ m!win32!i);
	return 'helvetica' if ($^O =~ m!solaris!i);
	return 'helvetica';
} # _font_family

# Private method: returns a font size suitable for the operating system.
sub _font_size {
	return 8 if ($^O =~ m!win32!i);
	return 12 if ($^O =~ m!solaris!i);
	return 10;
} # _font_family


sub background { my ($self,$operand)=(shift,shift);
	if (defined $operand){
		$self->{background} = $operand;
		return $operand;
	}
	elsif ($self->{-style} ne '95' and (
		$self->{wizardPagePtr}==0 or $self->{wizardPagePtr}==$#{$self->{wizardPageList}}
	)){
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
evaluate to C<Tk::Frame> objects, such as those returned by the methods
C<blank_frame> and C<addDirSelectPage>.

Pages are (currently) stored and displayed in the order added.

Returns the index of the page added, which is useful as a page UID when
peforming checks as the I<Next> button is pressed (see file F<test.pl>
supplied with the distribution).

See also L<METHOD blank_frame>.

=cut

sub addPage { my ($self, @pages) = (shift,@_);
	warn "# Enter addPage" if $self->{-debug};
	if (grep {ref $_ ne 'CODE'} @pages){
		croak "addPage requires one or more CODE references as arguments"
	}
	push @{$self->{wizardPageList}}, @pages;
}


=head2 METHOD Show

	$wizard->Show()

This method must be called before the Wizard will be displayed,
and must preced the C<MainLoop> call.

=cut

sub Show { my $self = shift;
	warn "# Enter Show" if $self->{-debug};
	return if exists $self->{_Shown};
	if ($^W and $#{$self->{wizardPageList}}==0){
		warn "# Showing a Wizard that is only one page long";
	}
	# The DirSelectPage used to contain some SERIOUSLY convoluted code
	# to create and navigate the DirTree, including chdirs all
	# over the place.  But it no longer chdirs all over the place
	$self->initial_layout;


	$self->resizable( 0, 0)	unless $self->{Configure}{-resizable} and $self->{Configure}{-resizable} =~/^(1|yes|true)$/i;
	$self->parent->withdraw;
	$self->Popup;
	$self->transient;               # forbid minimize
	$self->protocol( WM_DELETE_WINDOW => [ \&CloseWindowEventCycle, $self, $self]);
	$self->packPropagate(0);
	$self->configure(-background => $self->cget("-background"));
	$self->render_current_page;
	++$self->{_Shown};
	warn "# Leave Show" if $self->{-debug};
	return 1;
}


=head2 METHOD forward

Convenience method to move the Wizard on a page by invoking the
callback for the C<nextButton>.

You can automatically move forward after C<$x> tenths of a second
by doing something like this:

	$frame->after($x,sub{$wizard->forward});

=cut

sub forward { my $self=shift;
	return $self->NextButtonEventCycle;

	return $self->{nextButton}->invoke;
}

=head2 METHOD backward

Convenience method to move the Wizard back a page by invoking the
callback for the C<backButton>.

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
	warn "# Enter Initial_layout" if $self->{-debug};
	# Wizard 98/95 style
	if ($self->cget(-style) eq '95' or $self->{wizardPagePtr}==0){
		my $im = $self->cget(-imagepath);
		if (not ref $im){
			$self->Photo( "sidebanner", -file => $im );
		}
		else {
			$self->Photo( "sidebanner", -data => $$im );
#			$self->{left_object} = $self->Frame(-width=>100)->pack(qw/-side left -anchor w -expand 1 -fill both/);
		}
		$self->{left_object} = $self->Label( -image => "sidebanner")->pack( -side => "top", -anchor => "n");
	}

	# Wizard 2k style - builds the left side of the wizard
	else {
		my $im = $self->cget(-topimagepath);
		if (not ref $im){
			$self->Photo( "topbanner", -file => $im );
			$self->{left_object} = $self->Label( -image => "topbanner")->pack( -side => "top", -anchor => "e", );
		} else {
			$self->Photo( "topbanner", -data => $$im );
			$self->{left_object} = $self->Label( -image => "topbanner")->pack( -side => "top", -anchor => "e", );
#			$self->{left_object} = $self->Frame( -width => 250 )->pack( -side => "top", -anchor => "n", );
		}
	}
	$self->Advertise( imagePane => $self->{left_object} );
}


#
# Maybe sub-class me
#
sub render_current_page { my $self = shift;
	# Before doing anything on this page, chdir back to our start directory in case the
	# previously rendered page was a DirSelectPage which did some wild chdirs:
	warn "# Enter render_current_page $self->{wizardPagePtr}"  if $self->{-debug};
	my %frame_pack = ( -side => "top" );
	if (($self->{wizardPagePtr} > 0 and $self->{wizardPagePtr} < $#{$self->{wizardPageList}})
		and $self->{-style} ne '95'
	){
		$self->{tagtext}->packForget;
		$self->{tagline}->packForget;
		$self->{tagtext}->pack(-side=>'left', -anchor=>'e');
		$self->{tagline}->pack(-side=>'left', -anchor=>'e');
	} else {
		$self->{tagtext}->packForget;
		$self->{tagline}->pack(-side=>'left', -anchor=>'e');
	}

	if ( $self->{wizardPagePtr} == 0 or $self->{wizardPagePtr} == $#{$self->{wizardPageList}} ){
		$self->{left_object}->pack( -side => "left", -anchor => "w");
		if ($self->{-style} ne '95'){
			$frame_pack{-expand} = 1;
			$frame_pack{-fill} = 'both';
		}
	}
	elsif ($self->cget(-style) eq 'top'){
		$self->{left_object}->packForget;
	}

	# xxx
	$self->configure(-background=>$self->cget("-background"));
	$self->{wizardFrame}->packForget if $self->{wizardFrame} and ref $self->{wizardFrame} ne 'CODE';
	if (not defined $self->{wizardPageList}->[0]){
		Carp::croak 'render_current_page called without any frames: did you add frames to the wizard?';
	}
	$self->{wizardFrame} = $self->{wizardPageList}->[$self->{wizardPagePtr}]->()->pack(%frame_pack);
	if (ref $self->{wizardFrame}){
		$self->{wizardFrame}->update;
		$self->Advertise( wizardFrame => $self->{wizardFrame} );
	}
	$self->_resize_window;
	$self->{nextButton}->focus();
	warn "# Leave render_current_page $self->{wizardPagePtr}"  if $self->{-debug};
}


sub _resize_window { my $self=shift;
	if (ref $self->{wizardFrame}){
		if (exists $self->{frame_sizes}->[$self->{wizardPagePtr}] ){
			warn "Resize frame\n" if $self->{-debug};
			warn "			-width  => ".$self->{frame_sizes}->[$self->{wizardPagePtr}]->[0].",
				-height => ".$self->{frame_sizes}->[$self->{wizardPagePtr}]->[1]."\n" if $self->{-debug};
			$self->configure(
				-width  => $self->{frame_sizes}->[ $self->{wizardPagePtr} ]->[0],
				-height => $self->{frame_sizes}->[ $self->{wizardPagePtr} ]->[1]
			);
			$self->update;
		}
	}
}

=head2 METHOD currentPage

	my $current_page = $wizard->currentPage()

This returns the index of the page currently being shown to the user.
Page are indexes start at 1, with the first page that is associated with
the wizard through the C<addPage> method. See also the L<METHOD addPage> entry.

=cut

sub currentPage { my $self = shift;
	return $self->{wizardPagePtr} # + 1;
}

=head2 METHOD parent

	my $apps_main_window = $wizard->parent;

This returns a reference to the parent Tk widget that was used to create the wizard.

=cut

sub parent { return $_[0]->{Configure}{-parent} || shift }


=head2 METHOD blank_frame

	my $frame = wizard>->blank_frame(
		-title		=> $title,
		-subtitle	=> $sub,
		-text		=> $standfirst,
		-wait		=> $sometime
	);

Returns a C<Tk::Frame> object that is a child of the Wizard control, with
some C<pack>ing parameters applied - for more details, please see C<-style>
entry elsewhere in this document.

Arguments are name/value pairs:

=over 4

=item -title =>

Printed in a big, bold font at the top of the frame

=item -subtitle =>

Subtitle/standfirst.

=item -text =>

Main body text.

=item -wait =>

Experimental, maninly for test scripts.
The amount of time in thousands of a second to wait before moving forwards
regardless of the user. This actually just calls the C<forward> method (see
L<METHOD forward>). Use of this feature will enable the back-button even if
you have disabled it. What's more, if you page is supposed to wait for user
input, this feature will probably not give your users a chance.

See also: L<Tk::after>.

=back

Also:

	-width -height -background -font

=cut

#
# Sub-class me:
#	accept the args in the POD and return a Tk::Frame
#
sub blank_frame { my ($self,$args) = (shift,{@_});
	warn "# Enter blank_frame" if $self->{-debug};
	my ($main_bg);
	my $wrap = $args->{-wraplength} || 375;
	$args->{-font} = $self->{defaultFont} unless $args->{-font};

	# First and last pages are white
	if ($self->{wizardPagePtr}==0 or $self->{wizardPagePtr} == $#{$self->{wizardPageList}} ){
		$main_bg = $self->cget("-background");
	}
	# For 'top' style, main body is user choice (undef  by default)
	elsif ($self->cget(-style) eq 'top' and $self->{wizardPagePtr}>0){
		$main_bg = $self->cget("-background");# undef;
	}
	# For other styles (95 default), main body is userdefined or plain
	else {
		$main_bg = $args->{background} || $self->cget("-background");
	}

	# Frame is the page container
#	my $frame = $self->parent->Scrolled("Frame", -scrollbars=>'osoe',-width=>$main_wi, -height=>$args->{-height}||316, );

	$args->{-height} ||= $DEFAULT_HEIGHT;
	$args->{-width} ||= $DEFAULT_WIDTH;

	$self->{frame_sizes}->[$self->{wizardPagePtr}] = [ $args->{-width}, $args->{-height} ];
	warn "# Blank frame set width/height; $args->{-width}/$args->{-height}" if $self->{-debug};
	my $frame = $self->Frame(
		-width	=> $args->{-width},
		-height => $args->{-height}
	);

	$frame->configure(-background => $main_bg) if $main_bg;

	# For 'top' style pages other than first and last
	if ($self->cget(-style) eq 'top'
	and $self->{wizardPagePtr} > 0 and $self->{wizardPagePtr} != $#{$self->{wizardPageList}}
	){
		my $top_frame = $frame->Frame(-background=>'white')->pack(-fill=>'x',-side=>'top',-anchor=>'e');
 		my $p = $top_frame->Frame(-background=>'white');
		my $photo = $self->cget(-topimagepath);
		if (ref $photo){
			$p->Photo( "topimage", -data => $$photo );
		} else {
			$p->Photo( "topimage", -file => $photo );
		}
		$p->Label( -image => "topimage", -background=>'white')->pack( -side=>"right", -anchor=>"e", -padx=>5,-pady=>5);
		$p->pack(-side=>'right',-anchor=>'n');
		my $title_frame = $top_frame->Frame(-background=>'white')->pack(
			-side=>'left',-anchor=>'w',-expand=>1,-fill=>'x'
		);
		#
		# Is it better to call in Text::Wrap to indent, or
		# access font metrics and work out lengths and heights, or
		# just sod it and only support short lines?
		#
		if ($args->{-title}){
			# Padding left of title: -height should come from font metrics of TITLE_FONT_TOP;
			# 	but what about if the line wraps?
			$title_frame->Frame(qw/-background white -width 10 -height 30/)->pack(qw/-fill x -anchor n -side left/);
			# The title frame content proper:
			$title_frame->Label(
				-justify => 'left', -anchor=> 'w', -wraplength=>$wrap,
				-text=> $args->{-title},
				-font=>'TITLE_FONT_TOP', -background=>"white",
			)->pack(-side=>'top',-expand=>1,-fill=>'x',-pady=>5,-padx=>0);
		}
		# Smaller text in top
		if ($args->{-subtitle}){
			# Indent the subtitle - see note above
			$title_frame->Frame(qw/-background white -width 10 -height 12/)->pack(qw/-fill x -anchor w -side left/);
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

		# This is the line below top:
		if ($self->cget(-style) eq 'top' and $self->{wizardPagePtr}>0){
			my $top = $frame->Frame(
				-width => $frame->cget(-width) || $args->{-width},
				-background => $frame->cget("-background"),
				qw/ -relief groove -bd 1 -height 2/,
			)->pack(qw/-side top -fill x/);
		}

		# Text in body
		if ($args->{-text}){
			$args->{-text} =~ s/^[\n\r\f]//;
			$args->{-text} = "\n".$args->{-text};
			my $p = $frame->Label(
				-font => $args->{-font},
				-justify => 'left',  -anchor=> 'w',
				-wraplength => $wrap + 100,
				-justify => "left", -text => $args->{-text}
			)->pack(-side=>'top',-expand=>'1',-fill=>'x',-padx=>10);
			$p->configure(-background => $main_bg) if $main_bg ;
		}

	}

	# For wizards that are not 'top' style
	else {
		if ($args->{-title}){
			my $p = $frame->Label(
				-justify => 'left', -anchor => 'w',
				-wraplength => $wrap, -text => $args->{-title}, -font=>'TITLE_FONT',
			)->pack(-anchor=>'n',-side=>'top',-expand=>1,-fill=>'x');
			$p->configure(-background=>$main_bg) if $main_bg;
		}
		if ($args->{-subtitle}){
			$args->{-subtitle} =~ s/^[\n\r\f]//;
			$args->{-subtitle} = "\n".$args->{-subtitle};
			my $p  = $frame->Label(
				-font => $args->{-font},
				-justify => 'left',
				-anchor=> 'w',
				-wraplength=>$wrap, qw/-justify left/, -text => $args->{-subtitle},
			)->pack(-anchor=>'n',-side=>'top',-expand=>'1',-fill=>'x');
			$p ->configure(-background=>$main_bg) if $main_bg;
		} else {
			$frame->Label(); # intended so we can packForget first to $frame->children;
		}
		if ($args->{-text}){
			$args->{-text} =~ s/^[\n\r\f]//;
			$args->{-text} = "\n".$args->{-text};
			my $p = $frame->Label(
				-font		=> $args->{-font},
				-justify	=> 'left',
				-anchor		=> 'w',
				-wraplength	=> $wrap,
				-justify	=> "left",
				-text		=> $args->{-text},
			)->pack(-anchor=>'n',-side=>'top',-expand=>'1',-fill=>'x');
			$p->configure(-background=>$main_bg) if $main_bg;
		} else {
			$frame->Label(); # intended so we can packForget first to $frame->children;
		}
	}
#	my $p = $frame->Frame->pack(qw/-anchor s -side bottom -fill both -expand 1/);
#	$p->configure(-background => $frame->cget("-background") );
#	$p->packPropagate(0);

	if ($args->{-wait}){
		Tk::Wizard::fix_wait( \$args->{-wait} );
	#	$frame->after($args->{-wait},sub{$self->forward});
		$frame->after(
			$args->{-wait},sub {
				$self->{nextButton}->configure(-state=>'normal');
				$self->{nextButton}->invoke;
			}
		);
	}

	$frame->packPropagate(0);
	return $frame->pack(qw/-side top -anchor n -fill both -expand 1/);
} # end blank_frame



=head1 METHOD addTextFrame

Add to the wizard a frame containing a scrolling textbox, specified in
the parameter C<-boxedtext>. If this is a reference to a scalar, it is
taken to be plain text; if a plain scalar, it is taken to be the name
of a file to be opened and read.

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
			read IN,$$text,-s IN or warn;
			close IN or warn;
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
#         is undefined or if it should be dispatched.  Undefined methods are used to denote dispatchback
#         methods to bypass.  This reduces the number of method dispatchs made for each handler and also
#         increased the usability of the set methods when trying to unregister event handlers.
#
sub dispatch
  {
  my $handler = shift;
  # print STDERR " DDD dispatch($handler)\n";
  if (ref($handler) eq 'Tk::Callback')
    {
    return ! $handler->Call();
    } # if
  if (ref($handler) eq 'CODE')
    {
    return ! $handler->();
    } # if
  return 1;
  return (!($handler->())) if ((defined $handler)
                               && (ref $handler)
                               && (ref $handler eq 'Tk::Callback'));
  return $handler->Call(@_) if ((defined $handler)
                                && (ref $handler));
  # Below is the original 1.9451 version:
  return (!($handler->Call())) if defined $handler and ref $handler and ref $handler eq 'CODE';
  return 0;
  } # dispatch

#
# Method:      NextButtonEventCycle
# Description: Runs the complete view of the action handler cycle for the "Next>" button on the
#              wizard button bar. This includes dispatching the preNextButtonAction and
#              postNextButtonAction handler at the appropriate times.
#
sub NextButtonEventCycle { my $self = shift;
	if (dispatch( $self->cget(-preNextButtonAction) )) { return;}
	# Advance the wizard page pointer and then adjust the navigation buttons.
	# Redraw the frame when finished to get changes to take effect.
	$self->{wizardPagePtr}++;
	$self->{wizardPagePtr} = $#{$self->{wizardPageList}} if( $self->{wizardPagePtr} >= $#{ $self->{wizardPageList}});
	$self->{backButton}->configure( -state => "normal");
	if( $self->{nextButton}->cget("-text") eq $LABELS{FINISH}) {
		if ( dispatch( $self->cget(-preFinishButtonAction))) { return; }
		if ( dispatch( $self->cget(-finishButtonAction))) { return; }
		$self->{really_quit}++;
		$self->CloseWindowEventCycle();
		# Can't do anything now, we're dead
		# $self->destroy;
	} else {
		if ($self->{wizardPagePtr} == $#{ $self->{wizardPageList}}) {
			$self->{cancelButton}->packForget() if $self->{cancelButton};
			$self->{backButton}->packForget() if $self->{backButton};
			$self->{nextButton}->configure( -text => $LABELS{FINISH}) if $self->{nextButton};
		}
		$self->render_current_page;
                # print STDERR " DDD this is before dispatch postNextButtonAction\n";
		if (dispatch( $self->cget(-postNextButtonAction))) { return; }
	}
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



=head1 CloseWindowEventCycle

If this method recieves a true value from the C<-preCloseWindowAction> callback,
the calling object's C<destroy> method is called, by default closing the Wizard.

=cut

sub CloseWindowEventCycle { my ($self, $hGUI) = (shift,@_);
	warn "# Close window ec ... really=[$self->{really_quit}]\n" if $self->{-debug};
	unless ($self->{really_quit}){
		warn "# Really?\n" if $self->{-debug};
		if ($self->Callback( -preCloseWindowAction => $self->{-preCloseWindowAction} )){
			return;
		}
	}
#	return if dispatch( $self->cget(-preCloseWindowAction));
	warn "# DESTROY!\n" if $self->{-debug};
	$hGUI->destroy if defined $hGUI;
	if ($self->{Configure}{-kill_parent_on_destroy}){
		warn "Kill parent ".$self->parent." ".$self->{Configure}{-parent} if $self->{-debug};
		$self->parent->destroy;
	} else {
		$self->destroy; # Legacy
	}
	return undef;
}


=head1 DIALOGUE_really_quit

Returns true if we are to continue.
By default, may be called by closing the Wizard's window or pressing C<CANCEL>.

=cut

sub DIALOGUE_really_quit { my $self = shift;
	return 0 if $self->{nextButton}->cget(-text) eq $LABELS{FINISH};
	warn "# DIALOGUE_really_quit \n" if $self->{-debug};
	unless ($self->{really_quit}){
		warn "# Get really quit info\n" if $self->{-debug};
		my $button = $self->parent->messageBox('-icon' => 'question', -type => 'yesno',
		-default => 'no', -title => 'Quit Wizard??',
		-message => "The Wizard has not finished running.\n\nIf you quit now, the job will not be complete.\n\nDo you really wish to quit?");
		$self->{really_quit} = lc $button eq 'yes'? 1:0;
		warn "# ... really=[$self->{really_quit}]\n" if $self->{-debug};
	}
	return !$self->{really_quit};
}




=head1 METHOD addDirSelectPage

	$wizard->addDirSelectPage ( -variable => \$chosen_dir )

Adds a page (C<Tk::Frame>) that contains a scrollable tree list of all
directories including, on Win32, logical drives.

Supply in C<-variable> a reference to a variable to set the initial
directory, and to have set with the chosen path.

Supply C<-nowarnings> with a value of C<1> to list only drives which are
accessible, thus avoiding C<Tk::DirTree> warnings on Win32 where removable
drives have no media.

Supply C<-nowarnings> a value other than C<1> to avoid listing drives
which are both inaccessible and - on Win32 - are
either fixed drives, network drives, or RAM drives (that is types 3, 4, and
6, according to C<Win32API::File::GetDriveType>.

You may also specify the C<-title>, C<-subtitle> and C<-text> parameters, as
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
#             => !1: as 1, plus on types 3,4 and 6.
# -directory  => start dir
sub page_dirSelect { my ($self,$args) = (shift,shift);
	if (not $args->{-variable}){
		confess "You must supply a -variable parameter";
	} elsif (not ref $args->{-variable}){
		confess "The -variable parameter must be a reference";
	}
	my $_drives = sub {
		return '/' if $^O !~ /MSWin32/i;
		# Yuck: it does work, though. Somehow.
		eval('require Win32API::File');
		return Win32API::File::getLogicalDrives();
	};
	my ($frame,@pl) = $self->blank_frame(
		-title	  => $args->{-title} || "Please choose a directory",
		-subtitle => $args->{-subtitle}  || "After you have made your choice, press Next to continue.",
		-text	  => $args->{-text} || "",
		-wait	  => $args->{-wait} || undef,
	);

	$frame->Frame(-height=>10)->pack();
	my $entry	= $frame->Entry(
		-justify		=> 'left',
		-width			=> 40,
		-textvariable	=> $args->{-variable},
	)->pack(-side=>'top',-anchor=>'w',-fill=>"x", -padx=>10, -pady=>10,);
	$entry->configure(-background=>$self->cget("-background")) if $self->cget("-background");

	my $dirs = $frame->Scrolled ( "DirTree",
		-scrollbars => 'osoe',
		-selectbackground => "navy", -selectforeground => "white",-selectmode =>'browse',
		-width=>40, -height=>10,
		-browsecmd => sub { ${$args->{-variable}}=shift },
	)->pack(-fill=>"both",-padx=>10, -pady=>0, -expand=>1);
	$dirs->configure(-background=>$self->cget("-background")) if $self->cget("-background");
	$frame->Frame(-height=>10)->pack();

	my $mkdir = $frame->Button(
		-text => "New Directory",
        -command => sub {
			my $new_name = $self->prompt(-title=>'Create New Directory',-text=>"Please enter the name for the new directory");
			if ($new_name){
				$new_name =~ s/[\/\\]//g;
				$new_name = ${$args->{-variable}} ."/$new_name";
				if (! mkdir $new_name,0777){
					my $msg;
					if ($! =~ /Invalid argument/i){
						$msg = "The directory name you supplied is not valid.";
					} elsif ($! =~ /File Exists/i){
						$msg = "A directory with that name already exists.";
					} else {
						$msg = "The directory could not be created:\n\n\t'$!'"
					}
					$self->parent->messageBox(
						'-icon' => 'error', -type => 'ok',-title => 'Could Not Create Directory',
						-message => $msg,
					);
				} else {
					${$args->{-variable}} = $new_name;
					$dirs->configure(-directory => $new_name);
					$dirs->chdir($new_name);
				}
			} # if new_name
                                      }, # end of -command sub
	)->pack( -side => 'right', -anchor => 'w', -padx=>'10', );
	if ($self->{desktop_dir}){ # Thanks, Slaven Rezic.
		$frame->Button(
			-text => "Desktop",
			-command => sub {
				${$args->{-variable}} = $self->{desktop_dir};
				$dirs->configure(-directory => $self->{desktop_dir});
				$dirs->chdir($self->{desktop_dir});
			},
		)->pack( -side => 'right', -anchor => 'w', -padx=>'10', );
	}

	foreach my $d (&$_drives){
		($d) =~ /^(\w+:)/;
		if ($args->{-nowarnings} and ($args->{-nowarnings} eq "1"
		or $^O !~ /win/i)){
			my $cwd = Cwd::getcwd;
			$dirs->configure(-directory=>$d) if chdir $d;
			chdir $cwd;
		}
		elsif ($args->{-nowarnings}){ # Fixed drive only
			my $cwd = Cwd::getcwd;
			$dirs->configure(-directory=>$d) if Win32API::File::GetDriveType($d)==3 and chdir $d;
			chdir $cwd;
		}
		else {
			$dirs->configure(-directory=>$d);
		}
	}
	return $frame;
}


=head1 CALLBACK callback_dirSelect

A callback to check that the directory, passed as a reference in the sole
argument, exists, or can and should be created.

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


=head1 METHOD addFileSelectPage

  $wizard->addFileSelectPage(
                             -directory => 'C:/Windows/System32',
                             -variable => \$chosen_file,
                            );

Adds a page (C<Tk::Frame>) that contains a "Browse" button which pops up a file-select dialog box.
The selected file will be displayed in a read-only Entry widget.

Supply in C<-directory> the full path of an existing folder where the user's search shall begin.

Supply in C<-variable> a reference to a variable to have set with the chosen file name.

You may also specify the C<-title>, C<-subtitle> and C<-text> parameters, as
in L<METHOD blank_frame>.

=cut

sub addFileSelectPage
  {
  my ($self, $args) = (shift, {@_});
  $self->addPage( sub { $self->page_fileSelect($args) } );
  } # addFileSelectPage

#
# PRIVATE METHOD page_fileSelect
#
# As blank_frame plus:
# -variable => Reference to a variable to set.
# -directory  => start dir
sub page_fileSelect
  {
  my ($self,$args) = (shift,shift);
  # Verify arguments:
  if (not $args->{-variable})
    {
    confess "You must supply a -variable parameter";
    }
  elsif (not ref $args->{-variable})
    {
    confess "The -variable parameter must be a reference";
    }
  $args->{-directory} ||= '.';
  $args->{-title} ||= "Please choose an existing file";
  $args->{-subtitle} ||= "After you have made your choice, click 'Next' to continue.";
  $args->{-text} ||= '';
  # Create the mother frame:
  my ($frame, @pl) = $self->blank_frame(
                                        -title => $args->{-title},
                                        -subtitle => $args->{-subtitle},
                                        -text => $args->{-text},
                                        -wait => $args->{-wait},
                                       );
  # Put some space around the embedded elements:
  $frame->Frame(-height=>10)->pack(qw( -side top ));
  $frame->Frame(-height=>10)->pack(qw( -side bottom ));
  my $entry = $frame->Entry(
                            -justify => 'right',
                            -textvariable => $args->{-variable},
                            # For now (i.e. because we're lazy), don't
                            # let the user type in.  They must click
                            # the Browse button:
                            -state => 'readonly',
                           )->pack(-side => 'left',
                                   -anchor => 'w',
                                   -fill => "x",
                                   -expand => 1,
                                   -padx => 3,
                                  );
  $entry->configure(-background => $self->cget("-background")) if $self->cget("-background");
  my $bBrowse = $frame->Button(
                               -text => 'Browse...',
                               -command => sub
                                 {
                                 my $sFname = $frame->getOpenFile(
                                                                  -initialdir => $args->{-directory},
                                                                  -title => $args->{-title},
                                                                 );
                                 ${$args->{-variable}} = $sFname if $sFname;
                                 },
                              )->pack(qw( -side left -padx 3));
  return $frame;
  } # page_fileSelect


=head1 METHOD addTaskListPage

Adds a page to the Wizard that will perform a series of tasks, keeping the user
informed by ticking-off a list as each task is accomplished.

Whilst the task list is being executed, both the I<Back> and I<Next> buttons
are disabled.

Parameters are as for C<blank_frame> (see L<METHOD blank_frame>), plus:

=over 4

=item -tasks

The tasks to perform, supplied as a reference to an array, where each
entry is a pair (i.e. a two-member list), the first of which is a text
string to display, the second a reference to code to execute.

=item -delay

The length of the delay, in milliseconds, after the page has been
displayed and before execution the task list is begun. See L<the entry
for the 'after' routine in the Tk::After manpage|Tk::After>.

=item -continue

Display the next Wizard page once the job is done: invokes the
callback of the I<Next> button at the end of the task.

=item -todo_photo

=item -doing_photo

=item -ok_photo

=item -error_photo

In progress. Optional: all C<Tk::Photo> objects, displayed as appropriate.
C<-ok_photo> is displayed if the task code refernce returns a true value, otherwise
C<-error_photo> is displayed. These have defaults taken from L<Tk::Wizard::Image|Tk::Wizard::Image>.

=item -label_frame_title

The label above the C<Tk::LabFrame> object which
contains the task list. Default label is the boring C<Performing Tasks:>.

=item -frame_args

Optional: the arguments to pass in the creation of the C<Frame> object used to contain the list.

=item -frame_pack

Optional: array-refernce to pass to the C<pack> method of the C<Frame> containing the list.

=back

=head2 TASK LIST EXAMPLE

  $wizard->addTaskListPage(
      -title => "Toy example",
      -tasks => [
	     	"Wait five seconds" => sub { sleep 5 },
		 	"Wait ten seconds!" => sub { sleep 10 },
		],
	);

=cut

sub addTaskListPage { my ($self,$args) = (shift,{@_});
	$self->addPage( sub { $self->page_taskList($args)  } );
}


=head1 METHOD page_taskList

The same as C<addTaskListPage> (see L<METHOD addTaskListPage>)
but does not add the page to the Wizard.

Note that unlike C<addTaskListPage>, arguments are expected in a hash reference.

Useful for a task list that cannot be filled before the call
to C<Show()>.

Parameter C<-label_frame_title> is the label above the C<Tk::LabFrame> object which
contains the task list. Default label is the boring C<Performing Tasks:>.

=cut

sub page_taskList { my ($self,$args) = (shift,shift);
	my @tasks;
	my @states = qw[ todo doing ok error ];
	my $photos = {};

	foreach my $state (@states){
		if (not $args->{"-".$state."_photo"}){
			  $photos->{$state} = $self->Photo($state, -data => $Tk::Wizard::Image::TASK_LIST{$state} );
		}
		elsif  (!-r $args->{"-".$state."_photo"} or not $self->Photo($state, -file => $args->{"-".$state."_photo"})){
			warn "# Could not read -todo_photo at ".$args->{"-".$state."_photo"} if $^W;
		}
	}

	$args->{-frame_pack} = [ qw/-expand 1 -fill x -padx 40 -pady 10/ ] unless $args->{-frame_pack};
	$args->{-frame_args} = [
		-relief=>"flat",-bd=>0,
		-label => $args->{-label_frame_title} || "Performing Tasks: ",
		-labelside => "acrosstop"
	] unless $args->{-frame_args};

	my $frame = $self->blank_frame(
		-title	  => $args->{-title} || "Performing Tasks",
		-subtitle => $args->{-subtitle}  || "Please wait whilst the Wizard performs these tasks.",
		-text	  => $args->{-text}  || "",
		-wait	  => $args->{-wait} || undef,
	);
	my $main_bg = $frame->cget("-background");

	if ($#{$args->{-tasks}}>-1){
		my $task_frame = $frame->LabFrame( @{$args->{-frame_args}} )->pack( @{$args->{-frame_pack}} );
		$task_frame->configure(-background => $main_bg);

		foreach ( my $i=0; $i<=$#{$args->{-tasks}}; $i+=2 ){
			my $icn="-1";
			my $p = $task_frame->Frame(
				-background => $main_bg,
			)->pack(-side=>'top',-anchor=>"w");
			if (exists $photos->{todo}){
				$icn = $p->Label(
					-image=>"todo",
					-background => $main_bg,
					-anchor=>"w")->pack(-side=>"left"
				);
			}
			$p->Label(
				-text=>@{$args->{-tasks}}[$i],
				-background => $main_bg,
				-anchor=>"w")->pack(-side=>"left"
			);
			push @tasks, [$icn,@{$args->{-tasks}}[$i+1]];
		}
	} else {
		$args->{-delay} = 1;
	}
	$self->{nextButton}->configure(-state=>"disabled");
	$self->{backButton}->configure(-state=>"disabled");
	$frame->after( $args->{-delay} || 1000, sub {
		foreach my $task (@tasks){
			if (ref @$task[0]){
				@$task[0]->configure(-image => "doing")
			}
			$self->update;
			my $result = &{@$task[1]};
			if (ref @$task[0]){
				@$task[0]->configure(-image => $result? "ok" : "error")
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

Allow the user to make multiple choices among several options:
each choice sets a variable passed as reference to this method.

Accepts the usual parameters plus:

=over 4

=item -relief

For the checkbox buttons - see L<Tk::options>.

=item -choices

A reference to an array of hashes with the following fields:

=over 4

=item -title

Title of the option, will be rendered in bold

=item -subtitle

Text rendered smaller beneath the title

=item -variable

Reference to a variable that will contain the result of the choice.
Croaks if none supplied.

=item -checked

Pass a true value to specify that the box should initially
appear checked.

=back

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
		croak "No -variable!" if not $opt->{-variable};
		croak "-variable should be a reference!" if not ref $opt->{-variable};
		my $b = $content->Checkbutton(
			-text		=> $opt->{-title},
			-justify	=> 'left',
			-relief		=> $args->{-relief}||'flat',
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


=head1 DIALOGUE METHOD prompt

Equivalent to the JavaScript method of the same name: pops up
a dialogue box to get a text string, and returns it.  Arguments
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

#
# Using a -wait value for After of less than this seems to cause a weird Tk dump
# so call this whenever using a -wait
#
sub fix_wait {
	my $wait_ref = shift;
	$$wait_ref += 200 if $$wait_ref < 250;
}


1;

=head1 ACTION EVENT HANDLERS

A Wizard is a series of pages that gather information and perform tasks based upon
that information. Navigated through the pages is via I<Back> and I<Next> buttons,
as well as I<Help>, I<Cancel> and I<Finish> buttons.

In the C<Tk::Wizard> implementation, each button has associated with it one or more
action event handlers, supplied as code-references executed before, during and/or
after the button press.

The handler code should return a Boolean value, signifying whether the remainder of
the action should continue.  If a false value is returned, execution of the event
handler halts.

=over 4

=item -preNextButtonAction =>

This is a reference to a function that will be dispatched before the Next
button is processed.

=item -postNextButtonAction =>

This is a reference to a function that will be dispatched after the Next
button is processed. The function is called after the application has logically
advanced to the next page, but before the next page is drawn on screen.


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

=item -preFinishButtonAction =>

This is a reference to a function that will be dispatched just before the Finish
button action.

=item -finishButtonAction =>

This is a reference to a function that will be dispatched to handle the Finish
button action.

=item -preCancelButtonAction =>

This is a reference to a function that will be dispatched before the Cancel
button is processed.  Default is to exit on user confirmation - see
L<METHOD DIALOGUE_really_quit>.

=item -preCloseWindowAction =>

This is a reference to a function that will be dispatched before the window
is issued a close command. Default is to exit on user confirmation - see
L<DIALOGUE METHOD DIALOGUE_really_quit>.

=back

All active event handlers can be set at construction or using C<configure> -
see L<WIDGET-SPECIFIC OPTIONS> and L<METHOD configure>.

=head1 BUTTONS

	backButton nextButton helpButton cancelButton

If you must, you can access the Wizard's button through the object fields listed
above, each of which represents a C<Tk::Button> object. Yes, this is not a good
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

=head1 IMPLEMENTATION NOTES

This widget is implemented using the Tk 'standard' API as far as possible,
given my almost three weeks of exposure to Tk. Please, if you have a suggestion,
or patch, send it to me directly: C<LGoddard@CPAN.org>.

The widget is a C<MainWindow> and not a C<TopLevel> window. The reasoning is that
Wizards are applications in their own right, and not usually parts of other
applications. Although at the time of writing, I had only three weeks of Tk, I believe
it should be possible
to embed a C<Tk::Wizard> into another window using C<-use> and C<-container> -- but
any info on this practice would be appreciated.

There is one outstanding bug which came about when this Wizard was translated
from an even more naive implementation to the more-standard manner. That is:
because C<Wizard> is a sub-class of C<MainWindow>, the C<-background> is inaccessible
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

That modules beneath the base in the hierachy provide implementations based on
aesthetics and/or architecture.

=back

=head2 NOTES ON SUB-CLASSING Tk::Wizard

If you are planning to sub-class C<Tk::Wizard> to create a different display style,
there are three routines you will need to over-ride:

=over 4

=item initial_layout

=item render_current_page

=item blank_frame

=back

This may change, please bear with me.

=head1 CAVEATS, BUGS, TODO

=head1 POTENTIAL CAVEATS

In earlier versions of this still-alpha software, if you did not call the C<Wizard>'s C<destroy>
method, you would receive errors. This may or may not still be an issue for you. If it is, you can
"simply" proivde a callback to C<-finishButtonAction>:

	$wizard->configure(
		-finishButtonAction  => sub { $wizard->destroy;},
	);

Please let me know if you need to do this.

=over 4

=item *

Bit messy when composing frames.

=item *

Task Frame LabFrame backgrond colour doesn't set properly under 5.6.1.

=item *

20 January 2003: the directory tree part does not create directories
unless the eponymous button is clicked. Is this still an issue?

=item *

In Windows, with the system font set to > 96 dpi (via Display Properties / Settings
/ Advanced / General / Display / Font Size), the Wizard will not display propertly.
This seems to be a Tk feature.

=item *

Still not much of a Tk widget inheritance - any pointers welcome.

=item *

Nothing is currently done to ensure text fits into the window - it is currently up to
the client to make frames C<Scrolled>).

=back

=head1 CHANGES

Please see the file F<CHANGES.txt> included with the distribution.

=head1 AUTHOR

Lee Goddard (lgoddard@cpan.org) based on work Daniel T Hable.
Thanks to Martin Thurn (mthurn@cpan.org) for support and patches.

=head1 KEYWORDS

Wizard; set-up; setup; installer; uninstaller; install; uninstall; Tk; GUI.

=head1 COPYRIGHT

Copyright (c) Daniel T Hable, 2/2002.

Copyright (C) Lee Goddard, 11/2002 - 05/2005 ff

Patches Copyright (C) Martin Thurn 2005.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

THIS SOFTWARE AND THE AUTHORS OF THIS SOFTWARE ARE IN NO WAY CONNECTED
TO THE MICROSOFT CORP.

THIS SOFTWARE IS NOT ENDORSED BY THE MICROSOFT CORP

MICROSOFT IS A REGISTERED TRADEMARK OF MICROSOFT CROP.


=cut


__END__

