
=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

package PSQL::Connection::Manager;

use strict;
use warnings;
use DBI;

sub new {
    my $class = shift;
    my $self = {};
    $self->{connections} = {};
    return bless $self, $class;
}

sub is_connected {
    my ( $self, $ident ) = @_;
    my $ret = 0;
    $ret = 1 if $self->connections->{$ident}->{dbh};
    return $ret;
}

sub reconnect {
    my ( $self, $ident ) = @_;
    
    my $dbh = DBI->connect( $self->connections->{$ident}->{dsn}, 
        $self->connections->{$ident}->{user}, 
        $self->connections->{$ident}->{passwd} );

    $self->connections->{$ident}->{dbh} = $dbh;

    return 1;
}

sub disconnect {
    my ( $self, $ident ) = @_;
    $self->connections->{$ident}->{dbh}->disconnect();
    delete $self->connections->{$ident}->{dbh};
    return 1;
}

sub connect {
    my ( $self, $ident ) = @_;

    my $error = 0;

    if( $ident && exists $self->connections->{$ident} ) {
        my $dbh = DBI->connect( $self->connections->{$ident}->{dsn}, 
            $self->connections->{$ident}->{user}, 
            $self->connections->{$ident}->{passwd} ) or $error = 1;

         $self->connections->{$ident}->{dbh} = $dbh if not $error;
    } else {
        $error = 1;
    }

    return not $error;
}

sub connections {
    my $self = shift;
    return $self->{connections};
}

sub get {
    my ($self, $ident) = @_;
   
    my $dbh = -1;
    my $index = -1;

    if( not exists $self->connections->{$ident} ) {
        return ( $dbh, $index );  
    }  

    return ( $self->connections->{$ident}->{dbh}, $ident );
}

sub add {
    my ($self, $dsn, $user, $passwd, $name ) = @_;

    $self->connections->{$name} = {
        dsn => $dsn,
        user => $user,
        passwd => $passwd
        };

    return 1;
}

sub remove {
    my ($self, $ident) = @_;
    delete $self->{connections}->{$ident};
    return 1;
}

1;
