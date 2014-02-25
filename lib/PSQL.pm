package PSQL;

our $VERSION = 0.01;

use strict;
use warnings;
use Text::Table;
use Text::ASCIITable;
use PSQL::Connection::Manager;
use PSQL::Extension::Handler;
use PSQL::Context;
use Term::ReadLine;

=head1 NAME

PSQL - Another Perl SQL client

=head1 SYNOPSIS

A command line SQL client capable of connecting to any database
that DBI can interface with. 

Example:

$ perl -MPSQL -e 'new PSQL()'
psql>/connect mysql:test user password
psql>/use mysql:test
mysql:test>select * from foo

=head1 DESCRIPTION

Features that make PSQL worth using:
    Robust Tab Completion
    Multiple Connections
    Redirecting SQL output
    /record
    /export
    /run
    /edit

=head1 METHODS

=head2 new

An instance of this class creates a shell similiar to the mysql
command line client by capable of connecting to any DB supported
by DBI.  The object is not meant to be operated on and used in
a normal OO sense, as long as it exists in memory it will operate
a shell and act as a client and will exit when the user issues
an exit/quit command to the shell.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
	
    my $readline = new Term::ReadLine 'Perl SQL Client';
	my $cman = new PSQL::Connection::Manager();
	my $context = new PSQL::Context( $cman, -1, "" );
    $context->readline( $readline );	
    $context->prompt ( 'psql>' );
	my $handler = new PSQL::Extension::Handler();
	$handler->register( "PSQL::Extension::Basic" );
	$handler->register( "PSQL::Extension::SQL" );
	$handler->register( "PSQL::Extension::Jobs" );
    $context->handler( $handler );
    
    $self->context( $context );
    return $self;
}

sub context {
    my( $self, $context ) = @_;
    
    if( not defined $context ) {
        $context = $self->{context};
    } else {
        $self->{context} = $context;
    }

    return $context;
}

sub run {
    my $self = shift;
    my $context = $self->context();
    
	while ( defined( $_ = $context->readline->readline( 
        $context->prompt() ) ) ) {
        if( $_ eq "" ) {
            next;
        }

        $context->input( $_ );
	    if( not $context->handler()->seek( $context ) && length( $_ ) > 0 ) {
            $context->print( "[$_] I don't know how to respond to your request!\n" );
        }
	}
}

=head1 AUTHOR

Copyright (c) 2013 Kevin L. Kane. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
