use strict;
use warnings;

use FindBin;

use lib $FindBin::Bin.'/../bin';
require 'testrail-results';

use lib $FindBin::Bin.'/lib';
use Test::LWP::UserAgent::TestRailMock;

use Test::More 'tests' => 24;
use Capture::Tiny qw{capture_merged};
use List::MoreUtils qw{uniq};

no warnings qw{redefine once};
*TestRail::API::getTests = sub {
    my ($self,$run_id) = @_;
    return [
        {
            'id' => 666,
            'title' => 'fake.test',
            'run_id' => $run_id
        }
    ];
};

*TestRail::API::getTestResults = sub {
    return [
        {
            'elapsed' => '1s',
            'status_id'  => 5
        },
        {
            'elapsed' => '2s',
            'status_id' => 4,
            'comment'   => 'zippy'
        }
    ];
};

*TestRail::API::getPlanByID = sub {
    return {
        'id' => 40000,
        'name' => 'mah dubz plan',
        'entries' => [{
            'runs' => [
                {
                    'name' => 'planrun',
                    'id'   => '999',
                    'plan_id' => 40000
                }
            ]
        }]
    };
};

use warnings;

#check doing things over all projects/plans/runs
my @args = qw{--apiurl http://testrail.local --user test@fake.fake --password fake t/fake.test };
my ($out,$code) = TestRail::Bin::Results::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
is($code, 0, "Exit code OK looking for results of fake.test");
like($out,qr/fake\.test was present in 515 runs/,"Gets correct # of runs with test inside it");

#check project filters
@args = qw{--apiurl http://testrail.local --user test@fake.fake --password fake --project TestProject t/fake.test };
($out,$code) = TestRail::Bin::Results::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
is($code, 0, "Exit code OK looking for results of fake.test");
like($out,qr/fake\.test was present in 10 runs/,"Gets correct # of runs with test inside it when filtering by project name");

#check plan filters
@args = qw{--apiurl http://testrail.local --user test@fake.fake --password fake --plan };
push(@args,'mah dubz plan', 't/fake.test');
($out,$code) = TestRail::Bin::Results::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
is($code, 0, "Exit code OK looking for results of fake.test");
like($out,qr/fake\.test was present in 259 runs/,"Gets correct # of runs with test inside it when filtering by plan name");

#check run filters
@args = qw{--apiurl http://testrail.local --user test@fake.fake --password fake --run FinalRun t/fake.test};
($out,$code) = TestRail::Bin::Results::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
is($code, 0, "Exit code OK looking for results of fake.test");
like($out,qr/fake\.test was present in 1 runs/,"Gets correct # of runs with test inside it when filtering by run name");

#check pattern filters
@args = qw{--apiurl http://testrail.local --user test@fake.fake --password fake --grep zippy t/fake.test};
($out,$code) = TestRail::Bin::Results::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
is($code, 0, "Exit code OK looking for results of fake.test");
like($out,qr/Retest: 515/,"Gets correct # & status of runs with test inside it when grepping");
unlike($out,qr/Failed: 515/,"Gets correct # & status of runs with test inside it when grepping");

@args = qw{--apiurl http://testrail.local --user test@fake.fake --password fake --json t/fake.test };
($out,$code) = TestRail::Bin::Results::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
is($code, 0, "Exit code OK looking for results of fake.test in json mode");
like($out,qr/num_runs/,"Gets # of runs with test inside it in json mode");

#check defect filters
{
    no warnings qw{redefine once};
    local *TestRail::API::getTestByName = sub { return { 'id' => '666', 'run_id' => 123, 'elapsed' => 1 } };
    local *TestRail::API::getTestResults = sub { return [{ 'defects' => ['YOLO-666'], 'status_id' => 2  }, { 'defects' => undef, 'status_id' => 1 }] };
    @args = qw{--apiurl http://testrail.local --user test@fake.fake --password fake --defect YOLO-666 t/skip.test };
    ($out,$code) = TestRail::Bin::Results::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
    is($code, 0, "Exit code OK looking for defects of skip.test");
    like($out,qr/YOLO-666/,"Gets # of runs with defects inside it");
}

#For making the test data to test the caching
#open(my $fh, '>', "t/data/faketest_cache.json");
#print $fh $out;
#close($fh);

#Check caching
@args = qw{--apiurl http://testrail.local --user test@fake.fake --password fake --json --cachefile t/data/faketest_cache.json t/fake.test };
($out,$code) = TestRail::Bin::Results::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
is($code, 0, "Exit code OK looking for results of fake.test in json mode");
chomp $out;
is($out,"{}","Caching mode works");

#Check time parser
is(TestRail::Bin::Results::_elapsed2secs('1s'),1,"elapsed2secs works : seconds");
is(TestRail::Bin::Results::_elapsed2secs('1m'),60,"elapsed2secs works : minutes");
is(TestRail::Bin::Results::_elapsed2secs('1h'),3600,"elapsed2secs works : hours");
is(TestRail::Bin::Results::_elapsed2secs('1s1m1h'),3661,"elapsed2secs works :smh");

#Check help output
@args = qw{--help};
$0 = $FindBin::Bin.'/../bin/testrail-runs';
($out,(undef,$code)) = capture_merged {TestRail::Bin::Results::run('args' => \@args)};
is($code, 0, "Exit code OK asking for help");
like($out,qr/encoding of arguments/i,"Help output OK");

#Make sure that the binary itself processes args correctly
$out = `$^X $0 --help`;
like($out,qr/encoding of arguments/i,"Appears we can run binary successfully");
