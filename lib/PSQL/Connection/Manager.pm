
=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

package PSQL::Connection::Manager;

use strict;
use warnings;
use PSQL::Connection;

sub new {
    my $class = shift;
    my $self = {};
    $self->{connections} = {};
    return bless $self, $class;
}

sub connections {
    my $self = shift;
    return $self->{connections};
}

sub get {
    my ($self, $ident) = @_;
   
    my $dbh = -1;
    my $index = -1;

    if( not exists $self->{connections}->{$ident} ) {
        return ( $dbh, $index );  
    }  

    return ( $self->{connections}->{$ident}, $ident );
}

sub alias {
    my ( $self, $old, $new ) = @_;

    foreach my $name ( @{ $self->{names} } ) {
        $name = $new if $name eq $old;
    }

    return 1;
}

sub add {
    my ($self, $dsn, $user, $passwd, $name ) = @_;

    my $conn = new PSQL::Connection();
    $conn->name( $name );
    my $success = $conn->connect( $dsn, $user, $passwd );

    $self->{connections}->{$name} = $conn if $success;

    return $success;
}

sub remove {
    my ($self, $ident) = @_;
    my $success = 0;

    my ($dbh, $index) = $self->get( $ident );
    if( $index eq $ident ) {
        $self->{connections}->{$index}->disconnect();
        delete $self->{connections}->{$ident};
        $success = 1;
    }
    
    return $success;
}

1;
