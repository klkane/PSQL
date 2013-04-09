
=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

package PSQL::Extension::SQL;

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
    
    $self->{display_type} = 'table';
    my $is_sql = '(alter|show|explain|update|call|execute|insert|delete|select|drop|create|replace)';
    $self->{actions}{'^' . $is_sql} = \&PSQL::Extension::SQL::execute_sql;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'run'} = \&PSQL::Extension::SQL::execute_from_file;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'record'} = \&PSQL::Extension::SQL::record_sql;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'display'} = \&PSQL::Extension::SQL::display;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'desc'} = \&PSQL::Extension::SQL::describe;
}

=head2 describe

=cut

sub describe {
    my ($self, $context) = @_;
}

=head2 execute_sql

=cut

sub execute_sql {
    my ($self, $context) = @_;
    
    if( $context->default() != -1 ) { 
        my $dbh = $context->default()->{dbh};
        my $sth = $dbh->prepare( $context->input() );
        my $ret = $sth->execute();

        if( !$ret ) { 
            print $dbh->errstr . "\n";
        } else {
            if( $self->{_record_file} ) {
                open( FILE, ">>" . $self->{_record_file} );
                print FILE $context->input() . "\n";
                close( FILE );
            }

            if( $context->input() =~ /^(select|show|explain)/i ) { 
                if( $self->{display_type} eq 'table' ) {
                    $self->_table_display( $context, $sth );
                } elsif( $self->{display_type} eq 'csv' ) {
                    $self->_csv_display( $context, $sth );
                } else {
                    $self->_table_display( $context, $sth );
                }
            } else {
                print $sth->rows() . " rows affected\n";
            }   
        }   
    } else {
        print "No connection specified unable to do anything.\n";
    }   
    return 1;
}

=head2 _table_display

=cut

sub _table_display {
    my ($self, $context, $sth) = @_;
    my $at = new Text::ASCIITable( { headingText => $context->input() } );
    $at->setCols( @{ $sth->{NAME_lc} } );
    $at->addRow( $sth->fetchall_arrayref );    
    print $at;
}

=head2 _csv_display

=cut

sub _csv_display {
    my ($self, $context, $sth) = @_;
    print join( ',', @{ $sth->{NAME_lc} } ) . "\n";
    while( my @row = $sth->fetchrow_array ) {
        print join( ',', @row ) . "\n";
    }
}

=head2 execute_from_file

=cut

sub execute_from_file {
    my ($self, $context) = @_;
    my ($cmd, $file) = split / /, $context->input();
    if( -e $file ) {
        open FILE, $file or return print $!;
        my @lines = <FILE>;
        close FILE;
       
        chomp @lines; 
        my $giant_blob = join ' ', @lines;
        my @statements = split ';', $giant_blob;
        foreach my $sql ( @statements ) {
            $sql =~ s/^ *//;
            $context->input( $sql );
            $self->execute_sql( $context );
        }
    } else {
        print "File does not exist\n";
    }

    return 1;
}

=head2 display

Sets the display_type valid values are 'csv' and 'table'.

=cut

sub display {
    my ($self, $context) = @_;
    my ($cmd, $type) = split / /, $context->input();

    if( $type =~ /^(table|csv)$/ ) {
        $self->{display_type} = $type;
    } else {
        print "$type not recognized\n"; 
    }

    return 1;
}

=head2 record_sql

Accepts a filename or the keyword 'stop'.  All SQL statements
will be recorded to that filename until given the command to 
stop.

=cut

sub record_sql {
    my ($self, $context) = @_;
    my ($cmd, $file) = split / /, $context->input();
    
    if( $self->{_record_file} && $file eq "stop" ) {
        $self->{_record_file} = undef;
    } elsif( $self->{_record_file} ) {
        print "You are already recording to " . $self->{_record_file} . "\n";
    } else {
        $self->{_record_file} = $file;
    }

    return 1;
}

1;
