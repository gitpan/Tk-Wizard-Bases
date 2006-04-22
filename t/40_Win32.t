#! perl -w
our $VERSION = 0.4;	# 17:40 06 May 2005

use strict;
use Cwd;

BEGIN {
	if ($^O !~ /win/i){
		# "Thurn, Martin" <mthurn@northropgrumman.com>
		print "1..0 Skipped: MSWin32 module on $^O\n";
		exit;
	}
}

print "1..1\n";

use Tk::Wizard::Installer::Win32;
print "ok 1 # Sorry, no real tests yet.\n";

1;
