use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $prereq = {
	"Tk"				=> 0.1,
	"Tk::ProgressBar"	=> 0.1,
	"Tk::LabFrame"		=> 0.1,
	"File::Path"		=> 0.1,
};
# "Thurn, Martin" <mthurn@northropgrumman.com>
if ($^O =~ m/(mswin32|cygwin)/i){
  $prereq->{'Win32::TieRegistry'} = 0.1;
  $prereq->{'Win32::OLE'} = 0.1;
}
WriteMakefile(
    'ABSTRACT'	=> 'Create wizards with Perl TK.',
    'DISTNAME'	=> 'Tk-Wizard-Bases',
    'NAME'		=> 'Tk::Wizard',
    'VERSION'	=> 1.037,
    #'VERSION_FROM'	=> 'Wizard.pm', # finds $VERSION
    'PREREQ_PM'		=> $prereq,
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (#ABSTRACT_FROM => 'Wizard.pm', # retrieve abstract from module
       AUTHOR     => 'lgoddard -at- cpan -dot- org>') : ()),
);
