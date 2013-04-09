
=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

package PSQL::Extension::Handler;

use strict;
use warnings;
use Module::Load;

sub new {
    my ($class) = @_;
    my $self = ();
    @{ $self->{extensions} } = ();
    return bless $self, $class;
}


sub register {
    my ($self, $extension) = @_;
    
    if( defined $extension ) {
        eval "use $extension";
        warn $@ if $@;
        push @{ $self->{extensions} }, $extension->new();    
    }
}

sub seek {
    my ($self, $context) = @_;
    my $success = 0;
   
    foreach my $ext ( @{ $self->{extensions} } ) {
        if( $ext->poll( $context ) ) {
            $success = 1;
        }
    }

    return $success;
}

1;
