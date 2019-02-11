package Circuit::Spice::Parser;

# ABSTRACT: Parses a SPICE file as records

use Exporter 'import';
our (@EXPORT_OK) = ();
our (@EXPORT)    = (@EXPORT_OK);

=head1 SYNOPSIS

    use Circuit::Spice::Parser;

    ## ... code that uses your package

=cut

use Moose;
use MooseX::Modern;
use MooseX::SetOnce;
use String::Util 'collapse';

extends 'Text::Parser';

use constant {
    SPICE_LINE_CONTD => qr/^[+]\s*/,
    SPICE_CMD_STARTS => qr/^\./,
};

has '+multiline_type' => ( traits => ['SetOnce'], );

has '+auto_chomp' => ( traits => ['SetOnce'], );

has '+auto_trim' => ( traits => ['SetOnce'], );

has _inc_stack => (
    is         => 'rw',
    isa        => 'ArrayRef[Str]',
    auto_deref => 1,
    traits     => ['Array'],
    handles    => { _found_inc_file => 'find', },
);

sub BUILD {
    my $self = shift;
    $self->multiline_type('join_last');
    $self->auto_chomp(1);
    $self->auto_trim('b');
}

sub is_line_continued {
    my ( $self, $line ) = @_;
    return 0 if not defined $line;
    return $line =~ SPICE_LINE_CONTD;
}

sub join_last_line {
    my ( $self, $last, $line ) = ( shift, shift, shift );
    return $last if not defined $line;
    $line =~ s/^[+]\s*/ /;
    return $line if not defined $last;
    return collapse( $last . ' ' . $line );
}

sub save_record {
    my ( $self, $line ) = @_;
    $self->run_spice_cmd($line) if has_spice_cmd($line);
}

my %SYNTAX = (
    '.INCLUDE' => \&_dot_include,
    '.SUBCKT'  => \&_dot_subckt,
    '.ENDS'    => \&_dot_ends,
);

sub run_spice_cmd {
    my $self = shift;
    my ( $cmd, $rest ) = split /\s+/, shift, 2;
    $cmd = uc $cmd;
}

sub has_spice_cmd {
    my $line = shift;
    $line =~ SPICE_CMD_STARTS;
}

sub _dot_include {
    my ( $self, $rest ) = ( shift, shift );
    my $sp
        = Circuit::Spice::Parser->new( _inc_stack => [ $self->_inc_stack ] );
    $sp->read($rest);
    $self->push_records( $sp->get_records );
}

sub _syntax_checker {
    my ( $self, $line ) = ( shift, shift );
}

1;
