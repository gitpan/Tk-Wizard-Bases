package Tk::Wizard::Installer::Win32;
use vars qw/$VERSION/;
$VERSION = 0.04;	# Added addStartMenuPage

BEGIN {
	use Carp;
	use Tk::Wizard::Installer;
	require Exporter;
	@ISA = "Tk::Wizard::Installer";
	@EXPORT = ("MainLoop");
}

use Cwd;
use Win32::OLE;
use Win32::TieRegistry( Delimiter=>"/", ArrayValues=>0 );


=head1 NAME

Tk::Wizard::Installer::Win32 - Win32-specific routines for Tk::Wizard::Installer

=head1 DESCRIPTION

All the methods and means of C<Tk::Wizard> and C<Tk::Wizard::Installer>,
plus the below, which are thought to be specific to the Microsoft Windows
platform.

If you are looking for a freeware software installer that is not
dependant upon Perl, try Inno Setup - C<http://www.jrsoftware.org/>. It's
so good, even Microsoft have been caught using it.

If you are looking for a means to update the Windows C<Path> variable,
have a look for I<PathTool.exe>, a tiny Windows 32-bit executable
by Luke Bailey (C<luke@notts.flexeprint.com>). This tool can also be
used to add new, persistant environment variables to the system.

=head1 DEPENDENCIES

	Tk::Wizard
	Tk::Wizard::Installer
	Win32::TieRegistry
	HLIST
	Win32::OLE;
	Windows Scripting Host (for want of a better idea)

=head1 METHODS

=head2 METHOD register_with_windows

Registers an application with Windows so that it can be "uninstalled"
using the I<Control Panel>'s I<Add/Remove Programs> dialogue.

An entry is created in the Windows' registry pointing to the
uninstall script path. See C<UninstallString>, below.

Returns C<undef> on failure, C<1> on success.
Does nothing on non-MSWin32 platforms

Aguments are:

=over 4

=item uninstall_key_name

The name of the registery sub-key to be used. This is transparent to the
end-user, but should be unique for all applications.

=item UninstallString

The command-line to execute to uninstall the script.

According to L<Microsoft|http://msdn.microsoft.com/library/default.asp?url=/library/en-us/dnwue/html/ch11d.asp>:

	You must supply complete names for both the DisplayName and UninstallString
	values for your uninstall program to appear in the Add/Remove Programs
	utility. The path you supply to Uninstall-String must be the complete
	command line used to carry out your uninstall program. The command line you
	supply should carry out the uninstall program directly rather than from a
	batch file or subprocess.

The default value is:

	perl -e '$args->{app_path} -u'

This default assumes you have set the argument C<app_path>, and that it
checks and reacts to the the command line switch C<-u>:

	package MyInstaller;
	use strict;
	use Tk::Wizard;
	if ($ARGV[0] =~ /^-*u$/i){
		# ... Have been passed the uninstall switch: uninstall myself now ...
	}
	# ...

Or something like that.

=item QuiteUninstallString

As C<UninstallString> above, but for ... quiet uninstalls.

=item app_path

Please see the entry for C<UninstallString>, above.

=item DisplayName

=item DisplayVersion

=item Size

The strings displayed in the application list of the Add/Remove dialogue.

=item ModifyPath

=item NoRepair NoModify NoRemove

=item EstimatedSize InstallSorce InstallDate InstallLocation

=item AthorizedCDFPrefix Language ProductID

Unknown

=item Comments

=item RegOwner

=item RegCompnay

=item Contact

=item HelpTelephone

=item Publisher

=item URLUpdateInfo

=item URLInfoAbout

=item HelpLink

These are all displayed when the Support Information link
is clicked in the Add/Remove Programs dialogue. The last
should be full URIs.

=back

The routine will also try to add any other paramters to the
registry tree in the current location: YMMV.

=cut

sub register_with_windows { my ($self,$args) = (shift,{@_});
	return 1 if $^O!~/(mswin32|cygwin)/i;
	unless ($args->{DisplayName} and $args->{UninstallString}
		and ($args->{uninstall_key_name} or $args->{app_path})
	){
		die __PACKAGE__."::register_with_windows requires an argument of name/value pairs which must include the keys 'UninstallString', 'uninstall_key_name' and 'DisplayName'";
	}

	if (not $args->{UninstallString} and not $args->{app_path}){
		die __PACKAGE__."::register_with_windows requires either argument 'app_path' or 'UninstallString' be set.";
	}
	if ($args->{app_path}){
		$args->{app_path} = "perl -e '$args->{app_path} -u'";
	}
	my $uninst_key_ref =
	$Registry->{'LMachine/SOFTWARE/Microsoft/Windows/CurrentVersion/Uninstall/'} ->
		CreateKey( $args->{uninstall_key_name} );
	die "Perl Win32::TieRegistry error" if !$uninst_key_ref;

	foreach (keys %$args){
		next if $_ =~ /^(app_path|uninstall_key_name)$/g;
		$uninst_key_ref->{"/$_"} = $args->{$_};
	}
	return 1;
	# return $!? undef : 1;
}


=head1 METHOD addStartMenuPage

Returns a page (a filled C<Tk::Frame> object) that allows
users to select a location on the Windows "Start Menu",
perhaps to add a shortcut there.

This routine does not currently create the directory in the
I<Start Menu>, nor does it place a link there. Rather, the
caller supplies a C<-variable> paramter that is a reference
to a scalar which, once the page is 'run', will contain
either the path to the user's chosen directory, or C<undef>
if the option to not select was chosen.

In addition, when the page is 'run', it places the path to the
current user's I<Start Menu/Programs> directory into the object
field C<startmenu_dir_current>, and the path to the common
I<Start Menu/Programs> in the object field C<startmenu_dir_common>.

The adding of a shortcut is left as an exercise to the reader
until later this year, when I'll get around to finishing this.
Have a look at the C<$mkdir> C<Button> in C<Tk::Wizard::page_dirSelect>.

=over 4

=item -user

Set to C<current>, C<all> or C<both> to list the "Start Menu"
for all users, just the current user, or both. Default is C<both>.
If there exist entries in both the common and current user's
I<Start Menu> with the same name, the entry in the common menu
takes precedence.

=item -variable

The directory the user has chosen to create an item in. Note
this is I<not> the full path: see above.

=item -append

If this parameter evaluates to true, the name of the
directory defined by C<-variable> will be appended to any selection
made by the user.

=item -disable_nochoice

Set to prevent the display of the checkbox which
allows the user not to use this feature. See C<-label_nochoice>,
below.

=item -label_nochoice

If the paramter C<-disable_nochoice> has not been set,
C<-label_nochoice> should contains text to use for the label by the
checkbox which disables choices on
this page and causes the page to set the C<-variable> paramter to
C<undef>. Default text is C<Do not create a shortcut on the Start Menu>

=item -listHeight

Height of the list box, default is C<10> but you may
vary this if your C<-text> attribute takes up more or less much room.

=back

Accepts the Standard Options that are common to the C<HList> and
C<Label> widgets, but does not accept aliases:

	-relief -highlightthickness -background -borderwidth -cursor
	-highlightcolor -foreground -font

You can supply the common Wizard page options:

	-title -subtitle -text

=cut

sub addStartMenuPage { my ($self,$args) = (shift,{@_});
	return $self->addPage( sub { $self->page_start_menu($args)  } );
}


sub page_start_menu { my ($self,$args) = (shift,shift);
	local *DIR;
	my (@list,$dir);
	my $append;
	my $WshShell = Win32::OLE->CreateObject("WScript.Shell");
	my $cwd = cwd;
	my $do_set = 1;
	confess "You must set -variable parameter" unless exists $args->{-variable};
	$args->{-background} = 'white' unless exists $args->{-background};
	$args->{-relief} = 'sunken' unless exists $args->{-relief};
	$args->{-border} = 1 unless exists $args->{-border};
	$args->{-listHeight} = 10 unless exists $args->{-listHeight};
	$args->{-title} = "Create Shortcuts" unless exists  $args->{-title};
	$args->{-subtitle} = "Please select where to place an icon on the start menu" unless exists  $args->{-subtitle};
	$args->{-label_nochoice} = "Do not create a shortcut on the Start Menu" unless exists $args->{-label_nochoice};

	my $common_args;
	$common_args->{-background} = $args->{-background} if exists $args->{-background};
	$common_args->{-relief} = $args->{-relief} if exists $args->{-relief};
	$common_args->{-highlightthickness} = $args->{-highlightthickness} if exists $args->{-highlightthickness};
	$common_args->{-borderwidth} = $args->{-borderwidth} if exists $args->{-borderwidth};
	$common_args->{-cursor} = $args->{-cursor} if exists $args->{-cursor};
	$common_args->{-highlightcolor} = $args->{-highlightcolor} if exists $args->{-highlightcolor};
	$common_args->{-foreground} = $args->{-foreground} if exists $args->{-foreground};
	$common_args->{-font} = $args->{-font} if exists $args->{-font};

	my $variable = $args->{-variable};
	delete $args->{-variable};

	$append = $$variable if $args->{-append};

	my $frame = $self->blank_frame(%$args);

	$self->{startmenu_dir_current} = $WshShell->SpecialFolders(17);
	$self->{startmenu_dir_common}  = $WshShell->SpecialFolders(2);
	if ($args->{-user} eq 'current'){
		$dir = [$self->{startmenu_dir_current}];
	} elsif ($args->{-user} eq 'all') {
		$dir = [$self->{startmenu_dir_common}];
	} else {
		$dir = [
			$self->{startmenu_dir_common},
			$self->{startmenu_dir_current}
		];
	}
	foreach my $dodir (@$dir){
		chdir $dodir;
		opendir DIR,$dodir or croak "I couldn't open the start menu ($dodir)";
		push @list, grep {-d && !/^\.\.?$/ && s/^(.*)$/$dodir\\$1/} sort readdir DIR;
		close DIR;
	}
	chdir $cwd;
	my $listbox = $frame->Scrolled("HList",
		-scrollbars => "osoe",
		-selectmode => 'single',
		-height		=> $args->{-listHeight},
		-itemtype   => 'text',
		-separator  => '',
		-browsecmd	=> sub {
			$$variable = shift;
			$$variable .= "\\".$append if $append;
		},
		%$common_args
	)->pack(qw/ -expand 1 -fill x -padx 10 -pady 10 /);

	foreach my $i (@list){
		unless ($listbox->info("exists", $i)){
			$listbox->add( $i,
				-text => ($i)=~m/([^\\\/]+)$/
			) ;
		}
	}

	my $text	= $frame->Label( # Entry(
		-justify		=> 'left',
		-textvariable	=> $variable,
		-anchor => 'w',
		%$common_args
	)->pack(
		-side=>'top',-anchor=>'w',-expand=>1,-fill=>"x", -padx=>10,
	);

	my $button;

	unless ($args->{-disable_nochoice}){
		$button = $frame->Checkbutton(
			-text	=> $args->{-label_nochoice},
			-anchor	=> 'w',
			-command => sub {
				$do_set = !$do_set;
				if (not $do_set){	# De-activate
					$$variable = '';
					$text->configure(-background=>$self->cget(-background));
					$listbox->configure(-background=>$self->cget(-background));
				} else {
					$$variable = $listbox->info('anchor');
					$$variable .= "\\".$append if $append;
					$text->configure(-background=>$args->{-background});
					$listbox->configure(-background=>$args->{-background} );
				}
			},
		)->pack(qw/-side left -anchor w -padx 2 -pady 2/);
	};
	return $frame;
}
















# 1;
__END__



=head1 CHANGES

Please see the file F<CHANGES.txt> included with the distribution.

=head1 AUTHOR

Lee Goddard (lgoddard@cpan.org).

=head1 KEYWORDS

Wizard; set-up; setup; installer; uninstaller; install; uninstall; Tk; GUI; windows; win32; registry.

=head1 COPYRIGHT

Copyright (C) Lee Goddard, 11/2002 ff.

Distributed under the same terms as Perl itself.
