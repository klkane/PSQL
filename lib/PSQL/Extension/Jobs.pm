
=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

package PSQL::Extension::Jobs;

use strict;
use warnings;
use PSQL::Extension::Base;
use Text::Table;
use Text::ASCIITable;

our @ISA = qw( PSQL::Extension::Base );

=head2 init

=cut

sub init {
    my ($self) = @_;
    $self->SUPER::init();
   
    $self->{actions}{'\&$'} = \&PSQL::Extension::Jobs::new_job; 
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'jobs'} = \&PSQL::Extension::Jobs::jobs;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'kill'} = \&PSQL::Extension::Jobs::kill;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'wait'} = \&PSQL::Extension::Jobs::wait;
}

sub new_job {
    my ($self, $context) = @_;

    my $pid = fork();

    if( $pid ) {
        # parent
        if( not defined $self->{_job_list} ) {
            my %jobs;
            $self->{_job_list} = \%jobs;
        }
        $self->{_job_list}{$pid} = localtime;
        $context->print( "process $pid spawned\n" );
    } else {
        # child
        $context->default->reconnect();
        my $input = $context->input();
        $input =~ s/; *& */;/g;
        $context->input( $input );
        $context->buffer_output( "/tmp/psql_buffer.$$" );
        
        $context->handler->seek( $context );
        exit;
    }
}

sub jobs {
    my ($self, $context) = @_;
    foreach my $pid (keys %{ $self->{_job_list} } ) {
        $context->print( "$pid - " . $self->{_job_list}{$pid} . "\n" ); 
    }

    return 1;
}

sub kill {
    my ($self, $context) = @_;
    my ($cmd, $lvl, $pid) = split / /, $context->input();
    kill $lvl, $pid;
    waitpid( $pid, 0 );
    $context->print( "pid $pid killed\n" );
    return 1;
}

sub wait {
    my ($self, $context) = @_;
    my ($cmd, $pid) = split / /, $context->input();
    waitpid( $pid, 0 );
    open my $fh, "<", "/tmp/psql_buffer.$pid";

    while( <$fh> ) {
        $context->print( $_ );
    }
    return 1;
}

1;
