#! perl -w
our $VERSION = 0.3;	# 28 November 2002 23:30 CET

use strict;
use Cwd;

BEGIN
{
if ($^O ne 'MSWin32'){
	# "Thurn, Martin" <mthurn@northropgrumman.com>
	print "1..0 Skipped: MSWin32 module on $^O\n";
	exit;
}
}

print "1..1\n";

use Tk::Wizard::Installer::Win32;
print "ok 1\n";

1;
