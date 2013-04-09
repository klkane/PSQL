
=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

package PSQL::Connection;

use strict;
use warnings;
use DBI;

sub new {
    my $class = shift;

    my $self = {};

    return bless $self, $class;
}

sub dsn {
    my ($self, $dsn) = @_;
    
    if( $dsn ) {
        $self->{dsn} = $dsn;
    }

    return $self->{dsn};
}

sub connect {
    my ($self, $dsn, $user, $passwd) = @_;
   
    my $error = 0;
    if( $dsn ) { 
        my $dbh = DBI->connect( "dbi:$dsn", $user, $passwd ) 
            or $error = 1;
        $self->dsn( $dsn );
        $self->{dbh} = $dbh;
    }

    return not $error;
}

1;

