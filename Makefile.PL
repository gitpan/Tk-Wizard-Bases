use ExtUtils::MakeMaker;

my $prereq = {
              "Tk" => 0.1,
              "Tk::ProgressBar"	=> 0.1,
              "Tk::LabFrame" => 0.1,
              "File::Path" => 0.1,
             };
if ($^O =~ m/(mswin32|cygwin)/i)
  {
  $prereq->{'Win32::TieRegistry'} = 0.1;
  $prereq->{'Win32::Shortcut'} = 0.03;
  eval 'require Win32;';
  if (! $@)
    {
    eval '$_ = $Win32::VERSION;';
    if (! $@ && ($_ < 0.2))
      {
      eval 'require Win32::OLE;';
      warn "Win32.pm version is $_ (less than 0.2), therefore we will use Win32::OLE.  (This requires Windows Scripting Host which is present on Win98 and higher.)\n";
      $prereq->{'Win32::OLE'} = 0.1;
      }
    else
      {
      warn "Using Win32 for special folders...\n";
      $prereq->{'Win32'} = 0.2;
      }
    }
  else
    {
    die "There appears to be something wrong with your Perl installation. You are on a Windows platform without the core Win32 module. You can still use this module, but parts you will not be able to create shortcuts to the windows special folders.";
    }
  } # if win32 or cygwin
WriteMakefile(
              'ABSTRACT' => 'Create wizards with Perl-Tk',
              'DISTNAME' => 'Tk-Wizard-Bases',
              'NAME' => 'Tk::Wizard',
              'VERSION'	=> 1.07,
              'PREREQ_PM' => $prereq,
              ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
               (#ABSTRACT_FROM => 'Wizard.pm', # retrieve abstract from module
                AUTHOR => 'lgoddard -at- cpan -dot- org>') : ()
              ),
             );

__END__
