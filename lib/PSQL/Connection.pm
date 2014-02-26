
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

sub user {
    my ($self, $user) = @_;
    
    if( $user ) {
        $self->{user} = $user;
    }

    return $self->{user};
}

sub passwd {
    my ($self, $passwd) = @_;
    
    if( $passwd ) {
        $self->{passwd} = $passwd;
    }

    return $self->{passwd};
}

sub name {
    my ($self, $name) = @_;
    
    if( $name ) {
        $self->{name} = $name;
    }

    return $self->{name};
}

sub reconnect {
    my $self = shift;
    my $dbh = DBI->connect( $self->dsn, $self->user, $self->passwd );
    $self->{dbh} = $dbh;
    return 1;
}

sub connect {
    my ($self, $dsn, $user, $passwd) = @_;
   
    my $error = 0;
    if( $dsn ) { 
        my $dbh = DBI->connect( $dsn, $user, $passwd ) 
            or $error = 1;
        $self->dsn( $dsn );
        $self->user( $user );
        $self->passwd( $passwd );
        $self->{dbh} = $dbh;
    }

    return not $error;
}

1;

