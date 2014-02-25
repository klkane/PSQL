
=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

package PSQL::Context;

use strict;
use warnings;


sub new {
    my ($class,$connection_manager,$default,$input) = @_;
    my $self = {};
    bless $self, $class;
    $self->connection_manager( $connection_manager );
    $self->input( $input );
    $self->default( $default );
    return $self;
}

sub buffer_output {
    my ($self, $buffer_output) = @_;
    
    if( not defined $buffer_output ) {
        $buffer_output = $self->{buffer_output};
    } else {
        $self->{buffer_output} = $buffer_output;
    }

    return $buffer_output;
}

sub print {
    my ($self, $output) = @_;
   
    if( $self->buffer_output() ) {
        open FH, ">>" . $self->buffer_output();
        print FH $output;
        close FH;
    } else {
        if( $self->pipe() ) {
            open( my $fh, '|-', $self->pipe );
            print $fh $output;
            close( $fh );
            $self->{pipe} = undef;
        } else {
            print $output;
        }
    }

    return $output;
}

sub pipe {
    my ($self, $pipe) = @_;
    
    if( not defined $pipe ) {
        $pipe = $self->{pipe};
    } else {
        $self->{pipe} = $pipe;
    }

    return $pipe;
}

sub prompt {
    my ($self, $prompt) = @_;
    
    if( not defined $prompt ) {
        $prompt = $self->{prompt};
    } else {
        $self->{prompt} = $prompt;
    }

    return $prompt;
}

sub connection_manager {
    my ($self, $conn) = @_;

    if( not defined $conn ) {
        $conn = $self->{connection_manager};
    } else {
        $self->{connection_manager} = $conn;
    }

    return $conn;
}

sub default {
    my ($self, $input) = @_;
    
    if( not defined $input ) {
        $input = $self->{default};
    } else {
        $self->{default} = $input;
    }

    return $input;
}

sub last_input {
    my ($self, $last_input) = @_;
    
    if( not defined $last_input ) {
        $last_input = $self->{last_input};
    } else {
        $self->{last_input} = $last_input;
    }

    return $last_input;
}

sub input {
    my ($self, $input) = @_;
    
    if( not defined $input ) {
        $input = $self->{input};
    } else {
        $self->last_input( $self->{input} );
        $self->{input} = $input;
    }

    return $input;
}

sub term {
    my ($self, $term) = @_;
    
    if( not defined $term ) {
        $term = $self->{term};
    } else {
        $self->{term} = $term;
    }

    return $term;
}

sub handler {
    my ($self, $handler) = @_;
    
    if( not defined $handler ) {
        $handler = $self->{handler};
    } else {
        $self->{handler} = $handler;
    }

    return $handler;
}

sub readline {
    my ($self, $readline) = @_;
    
    if( not defined $readline ) {
        $readline = $self->{readline};
    } else {
        $self->{readline} = $readline;
    }

    return $readline;
}

1;
