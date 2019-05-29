use strict;
use warnings;
use Test::More tests => 39;
use Test::Exception;
use File::Temp qw/ tempdir /;
use Cwd;

use_ok(q{npg_tracking::status});

my $id_run = 1234;
my $status = q{analysis in progress};
my $dir = tempdir(UNLINK => 1);
my $current = getcwd();

{ 
  my $rls = npg_tracking::status->new(
      id_run => $id_run,
      lanes => [1],
      status => $status,
  );
  isa_ok( $rls, q{npg_tracking::status});
  like( $rls->timestamp,
    qr{\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\+\d\d\d\d},
    'timestamp generated');
  my $time_obj;
  lives_ok { $time_obj = $rls->timestamp_obj }
  'no error converting time from string to an object';
  isa_ok( $time_obj, q{DateTime});
  like ($time_obj->time_zone, qr/DateTime::TimeZone/, 'time zone is set');

  $rls = npg_tracking::status->new(
      id_run => $id_run,
      lanes => [1],
      status => $status,
      timestamp => q{2014/05/7 13:42:10}
  );
  throws_ok { $rls->timestamp_obj } qr/Your datetime does not match your pattern/,
    'error converting wrongly formatted time string';
}

{
  my @lanes = (7, 6, 5);

  my $rls = npg_tracking::status->new(
    id_run => $id_run,
    lanes => \@lanes,
    status => $status,
    timestamp => q{10/07/2014 13:42:10},
  );
  lives_ok {$rls->timestamp_obj} 'legacy format timestamp string parsed';

  $rls = npg_tracking::status->new(
    id_run => $id_run,
    lanes => \@lanes,
    status => $status,
    timestamp => q{2014-07-10T13:42:10+0100},
  );
  lives_ok {$rls->timestamp_obj} 'rfc3339-compliant timestamp parsed';

  my $time_obj;
  lives_ok { $time_obj = $rls->timestamp_obj }
    'no error converting time from string to an object';
  isa_ok( $time_obj, q{DateTime});

  my $filename = q{analysis-in-progress_5_6_7.json};
  is($rls->filename, $filename, q{lane filename built correctly});

  my $s;
  lives_ok{ $s = $rls->freeze() } q{object serialized};
  my $o;
  lives_ok{ $o = npg_tracking::status->thaw($s) } q{object deserialized};
  is ($o->timestamp, q{2014-07-10T13:42:10+0100}, 'timestamp correct');
  is ($o->status, $status, 'status correct');
  is ($o->id_run, $id_run, 'run id correct');
  is_deeply($o->lanes, \@lanes, 'lanes array correct');

  lives_ok { $o->to_file($dir) } 'serialization to a file';
  $filename = join(q[/], $dir, $filename);
  ok(-e $filename, 'file exists');
  my $new;
  lives_ok { $new = npg_tracking::status->from_file($filename)  } 'object read from  file';
  isa_ok($new, q{npg_tracking::status});
}

{
  my @lanes = (1);

  my $rls = npg_tracking::status->new(
    id_run => $id_run,
    lanes => \@lanes,
    status => $status,
    timestamp => q{2014-07-10T13:42:10+0000},
  );
  lives_ok {$rls->timestamp_obj} 'rfc3339-compliant timestamp parsed';

  my $filename = q{analysis-in-progress_1.json};
  is($rls->filename, $filename, qq{lane filename $filename built correctly});

  my $s;
  lives_ok{ $s = $rls->freeze() } q{object serialized};
  my $o;
  lives_ok{ $o = npg_tracking::status->thaw($s) } q{object deserialized};
  is ($o->timestamp, q{2014-07-10T13:42:10+0000}, 'timestamp correct');
  is ($o->status, $status, 'status correct');
  is ($o->id_run, $id_run, 'run id correct');
  is_deeply($o->lanes, \@lanes, 'lanes array correct');
}

{
  my $status = q{analysis complete};

  my $rls = npg_tracking::status->new(
    id_run => $id_run,
    status => $status,
    timestamp => q{10/07/2014 13:42:10 +0000},
  );
  lives_ok {$rls->timestamp_obj} 'legacy timestamp format parsed';

  my $run_filename = q{analysis-complete.json};
  is($rls->filename, $run_filename, q{run filename built correctly});
  my $s;
  lives_ok{ $s = $rls->freeze() } q{object serialized};
  my $o;
  lives_ok{ $o = npg_tracking::status->thaw($s) } q{object deserialized};
  is ($o->timestamp, q{10/07/2014 13:42:10 +0000}, 'timestamp correct');
  is ($o->status, $status, 'status correct');
  is ($o->id_run, $id_run, 'run id correct');
  is_deeply($o->lanes, [], 'lanes array is empty');
  chdir $dir;
  my $path = $o->to_file();
  ok(-e $path, 'file created in current directory');
  chdir $current;
}

END {
  eval {chdir $current};
}

1;
