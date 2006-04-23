#! perl -w

use ExtUtils::testlib;
use Test::More no_plan;

BEGIN {
	use lib '../lib';
	use_ok('Tk::Wizard')
};


my $VERSION = do { my @r = (q$Revision: 2.1 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
use warnings;
use strict;
use Cwd;

my $root = cwd =~ /\/t$/? '..' : '.';

my $wizard = new Tk::Wizard(
	-title 		=> "Test",
	-style		=> 'top',
);
isa_ok($wizard, "Tk::Wizard");

$wizard->addPage( sub{
	$wizard->blank_frame(
		-wait		=> 1000,
		-title		=> "Title One",
		-subtitle 	=>"It's just a test",
		-text 		=> "This Wizard is a simple test of the Wizard, and nothing more.\n\nNo software will be installed, but you'll hopefully see a licence agreement page, and a directory listing page.",
	);}
);
$wizard->addPage( sub{
	$wizard->blank_frame(
		-wait		=> 1000,
		-title		=> "Title Two",
		-subtitle 	=>"It's just a test",
		-text 		=> "This Wizard is a simple test of the Wizard, and nothing more.\n\nNo software will be installed, but you'll hopefully see a licence agreement page, and a directory listing page.",
	);}
);
$wizard->addPage( sub{
	$wizard->blank_frame(
		-wait		=> 1000,
		-title		=> "Title Three",
		-subtitle 	=>"It's just a test",
		-text 		=> "This Wizard is a simple test of the Wizard, and nothing more.\n\nNo software will be installed, but you'll hopefully see a licence agreement page, and a directory listing page.",
	);}
);

$wizard->Show;
MainLoop;
ok(1);
exit;



