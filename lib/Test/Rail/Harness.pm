# ABSTRACT: TestRail testing harness
# PODNAME: Test::Rail::Harness
package Test::Rail::Harness;

use strict;
use warnings;

use base qw/TAP::Harness/;

=head1 DESCRIPTION

Connective tissue for App::Prove::Plugin::TestRail.  Nothing to see here...

Subclass of TAP::Harness.

=head1 OVERRIDDEN METHODS

=head2 new

Tells the harness to use Test::Rail::Parser and passes off to the parent.

=cut

# inject parser_class as Test::Rail::Parser.
sub new {
    my $class = shift;
    my $arg_for = shift;
    $arg_for->{parser_class} = 'Test::Rail::Parser';
    my $self = $class->SUPER::new($arg_for);
    return $self;
}

=head2 make_parser

Picks the arguments passed to App::Prove::Plugin::TestRail out of $ENV and shuttles them to it's constructor.

=cut

sub make_parser {
    my ($self, $job) = @_;
    my $args = $self->SUPER::_get_parser_args($job);

    #XXX again, don't see any way of getting this downrange to my parser :(
    $args->{'apiurl'}  = $ENV{'TESTRAIL_APIURL'};
    $args->{'user'}    = $ENV{'TESTRAIL_USER'};
    $args->{'pass'}    = $ENV{'TESTRAIL_PASS'};
    $args->{'project'} = $ENV{'TESTRAIL_PROJ'};
    $args->{'run'}     = $ENV{'TESTRAIL_RUN'};
    $args->{'case_per_ok'}  = $ENV{'TESTRAIL_CASEOK'};
    $args->{'step_results'} = $ENV{'TESTRAIL_STEPS'};

    $self->SUPER::_make_callback( 'parser_args', $args, $job->as_array_ref );
    my $parser = $self->SUPER::_construct( $self->SUPER::parser_class, $args );

    $self->SUPER::_make_callback( 'made_parser', $parser, $job->as_array_ref );
    my $session = $self->SUPER::formatter->open_test( $job->description, $parser );

    return ( $parser, $session );
}

1;

__END__

=head1 SEE ALSO

L<TestRail::API>

L<Test::Rail::Parser>

L<App::Prove>

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.
