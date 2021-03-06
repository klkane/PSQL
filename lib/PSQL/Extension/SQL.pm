
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
    $self->{actions}{'^(select|insert|delete|update|show|explain)'} = \&PSQL::Extension::SQL::execute_sql;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'sql'} = \&PSQL::Extension::SQL::execute_sql;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'run'} = \&PSQL::Extension::SQL::execute_from_file;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'record'} = \&PSQL::Extension::SQL::record_sql;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'display'} = \&PSQL::Extension::SQL::display;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'desc'} = \&PSQL::Extension::SQL::describe;
    $self->{actions}{'^' . $self->{_CMD_CHAR} . 'timeout'} = \&PSQL::Extension::SQL::timeout;
}

=head2 describe

=cut

sub describe {
    my ($self, $context) = @_;
}


sub timeout {
    my ($self, $context ) = @_;
    my ( $cmd, $time ) = split / /, $context->input();
    $context->{config}->{timeout} = $time;
    return 1;
}

=head2 execute_sql

=cut

sub execute_sql {
    my ($self, $context) = @_;

    if( $context->input() =~ /&$/ ) {
        return 1;
    }   
 
    if( $context->default ) {
        my $dbh = $context->connection_manager->connections->{$context->default()}->{dbh};
        my $sql = $context->input();
        $sql =~ s/;$//g;
        $sql =~ s/^.sql//g;

        my $pipe;
        if( $sql =~ /; *\| *(.*)$/ ) {
            $pipe = $1;
            $sql =~ s/; *\| *.*$//g;
            $context->pipe( $pipe );
        }

        eval {
            $SIG{ALRM} = sub { die "timeout\n"; };
            eval {
	            alarm( $context->{config}->{timeout} );
		
		        my $sth = $dbh->prepare( $sql );
		        my $ret;
		
		        if( !$sth ) { 
		            $context->print( $dbh->errstr . "\n" );
		        } else {
		            $ret = $sth->execute();
		            if( !$ret ) {
		                $context->print( $dbh->errstr . "\n" );
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
			                } elsif( $self->{display_type} eq 'html' ) {
			                    $self->_html_display( $context, $sth );
			                } else {
			                    $self->_table_display( $context, $sth );
			                }
			            } else {
			                $context->print( $sth->rows() . " rows affected\n" );
			            }
		            }   
		        }
            };
            alarm( 0 );
            die "$@" if $@;
        };

        if( $@ && $@ eq "timeout\n" ) {
            $context->print( "Query timed out, timeout is currently " . $context->{config}->{timeout} . " seconds\n" );    
        }
    } else {
        $context->print( "No connection specified unable to do anything.\n" );
    }   

    return 1;
}

=head2 _table_display

=cut

sub _table_display {
    my ($self, $context, $sth ) = @_;
    my $at = new Text::ASCIITable();
    $at->setCols( @{ $sth->{NAME_lc} } );
    $at->addRow( $sth->fetchall_arrayref );    
    $context->print( $at );
}

=head2 _csv_display

=cut

sub _csv_display {
    my ($self, $context, $sth) = @_;
    $context->print( join( ',', @{ $sth->{NAME_lc} } ) . "\n" );
    while( my @row = $sth->fetchrow_array ) {
        $context->print( join( ',', @row ) . "\n" );
    }
}

sub _html_display {
    my ($self, $context, $sth) = @_;
    open( my $fh, ">", "/tmp/resultset.html" );
    print $fh "<html><body><table><tr><th>" . join( '</th><th>', @{ $sth->{NAME_lc} } ) . '</th></tr>';
    while( my @row = $sth->fetchrow_array ) {
        print $fh "<tr><td>";
        print $fh join( '</td><td>', @row );
        print $fh "</td></tr>";
    }
    print $fh "</table></body></html>";
    close( $fh );
   
    my $browser = $ENV{BROWSER} ||= 'lynx';
    system "$browser /tmp/resultset.html";
    unlink( "/tmp/resultset.html" ); 
}

=head2 execute_from_file

=cut

sub execute_from_file {
    my ($self, $context) = @_;
    my ($cmd, $file) = split / /, $context->input();
    if( -e $file ) {
        open FILE, $file or return $context->print( $! );
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
        $context->print( "File does not exist\n" );
    }

    return 1;
}

=head2 display

Sets the display_type valid values are 'csv' and 'table'.

=cut

sub display {
    my ($self, $context) = @_;
    my ($cmd, $type) = split / /, $context->input();

    if( $type =~ /^(table|csv|html)$/ ) {
        $self->{display_type} = $type;
    } else {
        $context->print( "$type not recognized\n" ); 
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
        $context->print( "You are already recording to " . $self->{_record_file} . "\n" );
    } else {
        $self->{_record_file} = $file;
    }

    return 1;
}

1;
