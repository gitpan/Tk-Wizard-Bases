
use ExtUtils::testlib;
use Test::More 'no_plan';
use warnings;
use strict;
use lib '../lib';
my $class;
BEGIN {
	$class = 'Tk::Wizard';
	use_ok($class)
};

my $wizard = new $class( -title => "Task List Test", );
isa_ok($wizard, $class);
isa_ok($wizard->parent, $class);
ok($wizard->addPage( sub{ &page_splash($wizard)} ));
ok($wizard->addTaskListPage(
	# -wait => 2,
	-continue => 2,
	-title => "TASK LIST EXAMPLE",
	-subtitle => "task list example",
	-tasks => [
			   "This task will succeed" => \&task_good,
			   "This task will fail!" => \&task_fail,
			   "Wizard will exit as soon as this one is done" => \&task_good,
			  ],
	),
);

$wizard->Show();
MainLoop;
exit;

sub task_good {
  sleep 1;
  return 1;
  }

sub task_fail {
  sleep 1;
  return 0;
  }

sub page_splash {
  my $wizard = shift;
  return $wizard->blank_frame(
                              -wait => 2,
                              -title => 'Task List Test',
                              -subtitle => 'task list test',
                              -text => 'Task list test',
                             );
  } # page_splash

__END__
