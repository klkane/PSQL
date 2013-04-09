
=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

package PSQL::Extension::Base;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->init();
    return $self;
}

sub init {
    my $self = shift;
    %{ $self->{actions} } = ();
    $self->{_CMD_CHAR} = '/';
    return 1;
}

sub poll {
    my ($self, $context) = @_;
    my $input = $context->input();

    my $success = 0;
    foreach my $pattern (keys %{ $self->{actions} }) {
        if( $input =~ /$pattern/ ) {
            my $func = $self->{actions}{$pattern};
            $success = $func->( $self, ($context) );
        }
    }

    return $success;
}

1;
