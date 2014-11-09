package Gnuplot::Builder::JoinDict;
use strict;
use warnings;
use Gnuplot::Builder::PartiallyKeyedList;
use Carp;
use overload '""' => "to_string";

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        separator => defined($args{separator}) ? $args{separator} : "",
        pkl => Gnuplot::Builder::PartiallyKeyedList->new,
        filter => $args{filter},
    }, $class;
    croak "filter must be a code-ref" if defined($self->{filter}) && ref($self->{filter}) ne "CODE";
    my $content = $args{content};
    $content = [] if not defined $content;
    croak "content must be an array-ref" if ref($content) ne "ARRAY";
    $self->_set_destructive(@$content);
    return $self;
}

sub to_string {
    my ($self) = @_;
    my $vals = defined($self->{filter})
        ? $self->{filter}->($self, [$self->{pkl}->get_all_keys], [$self->{pkl}->get_all_values])
        : [$self->{pkl}->get_all_values];
    if(ref($vals) ne "ARRAY") {
        croak "filter must return an array-ref";
    }
    return join($self->{separator}, grep { defined($_) } @$vals);
}

sub get {
    my ($self, $key) = @_;
    return undef if not defined $key;
    return $self->{pkl}->get($key);
}

sub set {
    my ($self, @content) = @_;
    return $self->clone->_set_destructive(@content);
}

sub _set_destructive {
    my ($self, @content) = @_;
    croak "odd number of elements in content" if @content % 2 != 0;
    foreach my $i (0 .. (@content / 2 - 1)) {
        my ($key, $value) = @content[2*$i, 2*$i+1];
        croak "undefined key in content" if not defined $key;
        $self->{pkl}->set($key, $value);
    }
    return $self;
}

sub clone {
    my ($self) = @_;
    my $clone = ref($self)->new(separator => $self->{separator}, filter => $self->{filter});
    $clone->{pkl}->merge($self->{pkl});
    return $clone;
}

sub delete {
    my ($self, @keys) = @_;
    my $clone = $self->clone;
    $clone->{pkl}->delete($_) foreach grep { defined($_) } @keys;
    return $clone;
}

sub separator {
    my ($self) = @_;
    return $self->{separator};
}

1;
__END__

=pod

=head1 NAME

Gnuplot::Builder::JoinDict - immutable ordered hash that joins its values in stringification

=head1 SYNOPSIS

    use Gnuplot::Builder::JoinDict;
    
    my $dict = Gnuplot::Builder::JoinDict->new(
        separator => ', ',
        content => [x => 640, y => 480]
    );
    "$dict";  ## => 640, 480
    
    $dict->get("x"); ## => 640
    $dict->get("y"); ## => 480
    
    my $dict2 = $dict->set(y => 16);
    "$dict";   ## => 640, 480
    "$dict2";  ## => 640, 16
    
    my $dict3 = $dict2->set(x => 8, z => 32);
    "$dict3";  ## => 8, 16, 32
    
    my $dict4 = $dict3->delete("x", "y");
    "$dict4";  ## => 32

=head1 DESCRIPTION

Basically L<Gnuplot::Builder::JoinDict> is just an ordered associative array (sometimes called as a "dictionary"),
so it's the same as L<Tie::IxHash>.

The difference from L<Tie::IxHash> is:

=over

=item *

L<Gnuplot::Builder::JoinDict> is B<immutable>. Every setter method doesn't alter the original object, but returns a new one.

=item *

When a L<Gnuplot::Builder::JoinDict> object is stringified, it B<joins> all its values with the given separator and returns the result.

=back

=head1 CLASS METHODS

=head2 $dict = Gnuplot::Builder::JoinDict->new(%args)

The constructor.

Fields in C<%args> are:

=over

=item C<separator> => STR (optional, default: "")

The separator string that is used when joining.

=item C<content> => ARRAY_REF (optional, default: [])

The content of the C<$dict>.
The array-ref must contain key-value pairs. Keys must not be C<undef>.

=item C<filter> => CODE_REF (optional)

If set, this code-ref is called when the C<$dict> is stringified (i.e. C<< $dict->to_string >> is called).
The code-ref is supposed to modify the values in C<$dict> to produce the final result of stringification.

    $modified_values_ref = $filter->($dict, $keys_ref, $values_ref)

where C<$dict> is the L<Gnuplot::Builder::JoinDict> object,
C<$keys_ref> is the array-ref of keys and C<$values_ref> is the array-ref of values.
The filter must return an array-ref C<$modified_values_ref>.

For example,

    my $dict = Gnuplot::Builder::JoinDict->new(
        separator => " & ", content => [x => 10, y => 20],
        filter => sub {
            my ($dict, $keys, $values) = @_;
            return [map { "$keys->[$_]=$values->[$_]" } 0 .. $#$keys]
        }
    );
    "$dict"; ## => x=10 & y=20

You can modify C<$keys_ref> and C<$values_ref> in the filter.
C<$dict> is not modified if you do that.

=back

=head1 OBJECT METHODS

=head2 $str = $dict->to_string()

Join C<$dict>'s values with the separator and return the result.

If some values are C<undef>, those values are ignored.

=head2 $value = $dict->get($key)

Return the C<$value> for the C<$key>.

If C<$dict> doesn't have C<$key>, it returns C<undef>.

=head2 $new_dict = $dict->set($key => $value, ...)

Add new key-value pairs to C<$dict> and return the result.
You can specify more than one key-value pairs.

If C<$dict> already has C<$key>, its value is replaced in C<$new_dict>.
Otherwise, a new pair of C<$key> and C<$value> is added.

=head2 $new_dict = $dict->delete($key, ...)

Delete the given keys from C<$dict> and return the result.
You can specify more than one C<$key>s.

If C<$dict> doesn't have C<$key>, it's just ignored.

=head2 $new_dict = $dict->clone()

Create and return a clone of C<$dict>.

=head2 $separator = $dict->separator()

Get the separator.

=head1 OVERLOAD

When you evaluate a C<$dict> as a string, it executes C<< $dict->to_string() >>. That is,

    "$dict" eq $dict->to_string;

=head1 AUTHOR

Toshio Ito, C<< toshioito at cpan.org >>

=cut
