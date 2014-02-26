
=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

package PSQL::Extension::Basic;

use strict;
use warnings;
use Term::Screen::Uni;
use PSQL::Extension::Base;

our @ISA = qw( PSQL::Extension::Base );

sub init {
    my ($self) = @_;
    $self->SUPER::init();
    
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'list'} = \&PSQL::Extension::Basic::list;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . '?(exit|quit)'} = \&PSQL::Extension::Basic::exit;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . '?clear'} = \&PSQL::Extension::Basic::clear;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'which'} = \&PSQL::Extension::Basic::which;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'connect'} = \&PSQL::Extension::Basic::connect;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'use'} = \&PSQL::Extension::Basic::use;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'disconnect'} = \&PSQL::Extension::Basic::disconnect;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . '?help'} = \&PSQL::Extension::Basic::help;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'load'} = \&PSQL::Extension::Basic::load;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'register'} = \&PSQL::Extension::Basic::register;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'edit'} = \&PSQL::Extension::Basic::edit;
}

sub edit {
    my ($self, $context) = @_;
    my( $cmd, $opt ) = split / /, $context->input();

    my $file = "/tmp/psql_12321313.tmp";    

    if( $opt && $opt eq "last" ) {
        open( my $fh, "> $file" );
        print $fh $context->last_input();
        close( $fh );
    } 

    my $editor = $ENV{EDITOR} || "vi";
    system "$editor $file";
    open( my $fh, "< $file" );
    undef $/; 
    my $text = <$fh>; 
    $/ = "\n";
    close $fh; 
    unlink $file; 
    $context->print( $text );
    $context->input( $text );
    return 1;
}

sub register {
    my ($self, $context) = @_;
    my ($cmd, $class) = split / /, $context->input();
    $context->handler()->register( $class );
    return 1;
}

sub load {
    my ($self, $context) = @_;
    my ($cmd, $file) = split / /, $context->input();
 
    if( -e $file ) { 
        open FILE, $file or return $context->print( $! ); 
        my @lines = <FILE>;
        close FILE;
    
        chomp @lines;
        foreach my $cmd (@lines) {
            $context->input( $cmd );
            $context->handler()->seek( $context );
        } 
    } else {
        $context->print( "File does not exist\n" );
    }   

    return 1;
}

sub use {
    my ($self, $context) = @_;
    my ($cmd,$ident) = split / /, $context->input();

    if( $context->default( $context->connection_manager()
        ->get( $ident ) ) ) {
        $context->prompt( $context->default->name() . '>' );
        $context->print( "Default database set to $ident\n" );    
    } else {
        $context->print( "Can't find database $ident, doing nothing\n" );
    }
}

sub disconnect {
    my ($self, $context) = @_;
    $context->print( "TODO DISCONNECT\n" );
    return 1;
}

sub help {
    my ($self, $context) = @_;
    $context->print( "Commands(commands should be preceded by a '" . $self->{_CMD_CHAR}  . "'):\n" );
    $context->print( "    " );
    $context->print( " list|exit|quit|which|connect|use\n\n" );
    $context->print( "Example:\n" );
    $context->print( "    " );
    $context->print( "psql>" . $self->{_CMD_CHAR} . "list\n\n" );
    return 1;
}

sub alias {
    my ( $self, $context ) = @_;
    my ($cmd, $number, $alias) = split / /, $context->input();

    return 1;
}

sub connect {
    my ($self, $context) = @_;
    my ($cmd, $name, $dsn, $user, $passwd) = split / /, $context->input();
    if( $context->connection_manager()->add( $dsn, $user, $passwd, $name ) ) {
        $context->print( "Conntected to $dsn\n" );
    } 
    
    return 1;
}

sub list {
    my ($self, $context) = @_;
    my $i = 0;
    foreach my $conn ( keys %{ $context->connection_manager()->connections() } ) {
        $context->print( "$conn: " . $context->connection_manager->connections->{$conn}->dsn() . "\n" );
    }
    return 1;
}

sub which {
    my ($self, $context) = @_;
    $context->print( $context->default() . "\n" );
    return 1;
}

sub clear {
    my ($self, $context) = @_;
    my $scr = new Term::Screen::Uni();
    $scr->clrscr();
    return 1;
}

sub exit {
    my ($self, $context) = @_;
    exit;
    return 1;
}

1;
