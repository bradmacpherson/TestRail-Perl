use strict;
use warnings;

#Test things we can only mock, because the API doesn't support them.

use Test::More 'tests' => 5;
use TestRail::API;
use Test::LWP::UserAgent::TestRailMock;
use Scalar::Util qw{reftype};

my $browser = $Test::LWP::UserAgent::TestRailMock::mockObject;
my $tr = TestRail::API->new('http://hokum.bogus','fake','fake',1);
$tr->{'browser'} = $browser;
$tr->{'debug'} = 0;

my $project = $tr->getProjectByName('TestProject');
my $plan    = $tr->getPlanByName($project->{'id'},'HooHaaPlan');
my $runs = $tr->getChildRuns($plan);
is(reftype($runs),'ARRAY',"getChildRuns returns array");
is(scalar(@$runs),4,"getChildRuns with multi-configs in the same group returns correct # of runs");

my $summary = $tr->getPlanSummary($plan->{'id'});
is($summary->{'plan'},1094,"Plan ID makes it through in summary method");
is($summary->{'totals'}->{'untested'},4,"Gets total number of tests correctly");
is($summary->{'percentages'}->{'untested'},'100.00%',"Gets total percentages correctly");
