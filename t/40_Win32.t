#! perl -w
our $VERSION = 0.5;	# 03 June 2006

use strict;
use Cwd;

BEGIN {
	use lib '../lib';
	use Test::More;
	if( $^O !~ /win/i ) {
		plan skip_all => "MSWin32 module on $^O";
	}
	else {
		plan tests => 1;
	}
}

use_ok("Tk::Wizard::Installer::Win32");


1;
