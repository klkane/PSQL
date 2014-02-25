
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

    @{ $self->{connections} } = ();
    @{ $self->{names} } = ();

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

    if( not defined $ident ) {
        return ( $dbh, $index );  
    }  

    for(my $i = 0; $i < scalar( $self->{names} ); $i++ ) {
        if( $self->{names}[$i] eq $ident or
            $ident == $i ) {
            $dbh = $self->{connections}[$i];
            $index = $i;
            last;
        }
    }

    return ( $dbh, $index );  
}

sub alias {
    my ( $self, $old, $new ) = @_;

    foreach my $name ( @{ $self->{names} } ) {
        $name = $new if $name eq $old;
    }

    return 1;
}

sub add {
    my ($self, $dsn, $name, $passwd) = @_;

    if( not defined $name ) {
        $name = scalar( @{ $self->{connections} } );
    }

    my $conn = new PSQL::Connection();
    my $success = $conn->connect( $dsn, $name, $passwd );

    push @{ $self->{connections} }, $conn if $success;     
    push @{ $self->{names} }, $name if $success;

    return $success;
}

sub remove {
    my ($self, $ident) = @_;
    my $success = 0;

    my ($dbh, $index) = $self->get( $ident );
    if( $index >= 0 ) {
        $self->{connections}[$index]->disconnect();
        delete $self->{connections}[$index];
        delete $self->{names}[$index];
        $success = 1;
    }
    
    return $success;
}

1;
