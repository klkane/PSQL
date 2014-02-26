
=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

package PSQL::Extension::GPG;

use strict;
use warnings;
use PSQL::Extension::Base;

our @ISA = qw( PSQL::Extension::Base );

sub init {
    my ($self) = @_;
    $self->SUPER::init();
    
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'gpg load'} = \&PSQL::Extension::GPG::load;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'gpg save'} = \&PSQL::Extension::GPG::save;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'gpg help'} = \&PSQL::Extension::GPG::help;
}

sub load {
    my ( $self, $context ) = @_;
    my ( $par, $cmd, $file ) = split / /, $context->input();
    $file = "~/.psql-gpg.conf.gpg" if not $file;

    open( my $fh, '-|', "gpg -d $file" );

    my $old_in = $context->input();    
    while( my $in = <$fh> ) {
        chomp( $in );
        $context->input( $in );
        $context->handler()->seek( $context );
    }
    $context->input( $old_in );
    close( $fh );
}

sub save {
    my ( $self, $context ) = @_;
    my ( $par, $cmd, $file ) = split / /, $context->input();
    $file = "~/.psql-gpg.conf" if not $file;

    open( my $fh, "> $file" );

    foreach my $conn ( keys %{ $context->connection_manager->connections } ) {
        print $fh "/add $conn " . 
            $context->connection_manager->connections->{$conn}->{dsn} . " " .
            $context->connection_manager->connections->{$conn}->{user} . " " .
            $context->connection_manager->connections->{$conn}->{passwd} . "\n";
    }   
 
    system( "gpg -c $file" );
    unlink( $file );
    $context->print( "$file.gpg written\n" );
    return 1;
}

sub help {
    my ( $self, $context ) = @_;
}

1;
