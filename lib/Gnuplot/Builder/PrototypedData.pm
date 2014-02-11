package Gnuplot::Builder::PrototypedData;
use strict;
use warnings;
use Gnuplot::Builder::PartiallyKeyedList;
use List::Util 1.28 qw(pairs);

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        list => Gnuplot::Builder::PartiallyKeyedList->new,
        attributes => {},
        parent => undef,
        entry_evaluator => $args{entry_evaluator},
    }, $class;
    return $self;
}

sub _trim_whitespaces {
    my ($val) = @_;
    $val =~ s/^\s+//g;
    $val =~ s/\s+$//g;
    return $val;
}

sub _parse_pairs {
    my ($pairs_str) = @_;
    my @pairs = ();
    my $carried = "";
    foreach my $line (split /^/, $pairs_str) {
        $line =~ s/[\r\n]+$//g;
        if($line =~ /\\$/) {
            $carried .= substr($line, 0, -1);
            next;
        }
        $line = $carried . $line;
        $carried = "";
        next if $line =~ /^#/;
        $line =~ s/^\s+//g;
        next if $line eq "";
        if($line =~ /^([^=]*)=(.*)$/) {
            my ($name, $value) = ($1, $2);
            push(@pairs, _trim_whitespaces($name), _trim_whitespaces($value));
        }else {
            my $name = _trim_whitespaces($line);
            if($name =~ /^-/) {
                push(@pairs, substr($name, 1), undef);
            }else {
                push(@pairs, $name, "");
            }
        }
    }
    return \@pairs;
}

sub set_entry {
    my ($self, %args) = @_;
    my $prefix = defined($args{key_prefix}) ? $args{key_prefix} : "";
    my $quote = $args{quote};
    my $entries = $args{entries};
    if(@$entries == 1) {
        $entries = _parse_pairs($entries->[0]);
    }
    
    ## Multiple occurrences of the same key are combined into an array-ref value.
    my $temp_list = Gnuplot::Builder::PartiallyKeyedList->new;
    foreach my $entry_pair (pairs @$entries) {
        my ($given_key, $value) = @$entry_pair;
        my $key = $prefix . $given_key;
        if($temp_list->exists($key)) {
            push(@{$temp_list->get($key)}, $value);
        }else {
            $temp_list->set($key, [$value]);
        }
    }
    $temp_list->each(sub {
        my ($key, $value_arrayref) = @_;
        my $value = (@$value_arrayref == 1) ? $value_arrayref->[0] : $value_arrayref;
        $self->{list}->set($key, $quote ? _wrap_value_with_quote($value) : $value);
    });
}

sub _quote_gnuplot_str {
    my ($str) = @_;
    return undef if !defined($str);
    $str =~ s/'/''/g;
    return qq{'$str'};
}

sub _wrap_value_with_quote {
    my ($value) = @_;
    my $ref = ref($value);
    if($ref eq "ARRAY") {
        return [map { _quote_gnuplot_str($_) } @$value];
    }elsif($ref eq "CODE") {
        return sub {
            return map { _quote_gnuplot_str($_) } $value->(@_);
        };
    }else {
        return _quote_gnuplot_str($value);
    }
}

sub add_entry {
    my ($self, @entries) = @_;
    $self->{list}->add($_) foreach @entries;
}

sub delete_entry { $_[0]->{list}->delete($_[1]) }

sub has_own_entry { return $_[0]->{list}->exists($_[1]) }

sub set_parent { $_[0]->{parent} = $_[1] }

sub parent { return $_[0]->{parent} }

sub _create_inheritance_stack {
    my ($self) = @_;
    my @pdata_stack = ($self);
    my $current = $self;
    while(defined(my $parent = $current->parent)) {
        push(@pdata_stack, $parent);
        $current = $parent;
    }
    return \@pdata_stack;
}

sub _create_merged_pkl {
    my ($self) = @_;
    my $result = Gnuplot::Builder::PartiallyKeyedList->new;
    my $pdata_stack = $self->_create_inheritance_stack();
    while(defined(my $cur_pdata = pop(@$pdata_stack))) {
        $result->merge($cur_pdata->{list});
    }
    return $result;
}

sub _normalize_value {
    my ($raw_value, $evaluator, $key) = @_;
    my $ref = ref($raw_value);
    if($ref eq "ARRAY") {
        return @$raw_value;
    }elsif($ref eq "CODE" && defined($evaluator)) {
        return $evaluator->($key, $raw_value);
    }else {
        return ($raw_value);
    }
}

sub get_resolved_entry {
    my ($self, $key) = @_;
    my $merged = $self->_create_merged_pkl();
    return () if !$merged->exists($key);
    my $raw_value = $merged->get($key);
    return _normalize_value($raw_value, $self->{entry_evaluator}, $key);
}

sub each_resolved_entry {
    my ($self, $code) = @_;
    my $merged = $self->_create_merged_pkl();
    $merged->each(sub {
        my ($key, $raw_value) = @_;
        $code->($key, [_normalize_value($raw_value, $self->{entry_evaluator}, $key)]);
    });
}

1;

__END__

=pod

=head1 NAME

Gnuplot::Builder::PrototypedData - generic prototype-based object

=head1 DESCRIPTION

This is an internal module for L<Gnuplot::Builder> distribution.
B<< End-users should not rely on this module >>.

L<Gnuplot::Builder::PrototypedData> is a generic data structure depicted below.

    PrototypedData
        |
        +--PartiallyKeyedList--+--entry
        |                      +--entry
        |                      +--...
        |
        +--attributes--{ key => value ... }
        |
        +--parent

=over

=item *

It contains a L<Gnuplot::Builder::PartiallyKeyedList> and a hash.
The hash is called "attributes" here.

=item *

It supports prototype-based inheritance for both PartiallyKeyedList and attributes.

=item *

Entries and attribute values can be code-ref.
If an "evaluator" is provided for the entries or attributes,
the code-ref is automatically evaluated when you try to get the value.
If there is no evaluator for the entry or attribute, it just returns the code-ref.

=back

=head1 CLASS METHODS

=head2 $pdata = Gnuplot::Builder::PrototypedData->new(%args)

In C<%args>:

=over

=item C<entry_evaluator> => CODE

The evaluator for PKL entries. It is called like:

    @result = $evaluator->($key, $value_code_ref)

For non-keyed entries, C<$key> is C<undef>.

=item C<attribute_evaluator> => HASH

The key-evaluator pairs for attributes.

    { $attribute_name => $evaluator }
    @result = $evaluator->($attribute_name, $value_code_ref)

=back


=head1 OBJECT METHODS

=head2 $pdata->set_entry(%args)

Set PKL entry. In C<%args>,

=over

=item C<entries> => ARRAY-REF (mandatory)

Array-ref of entry settings. If it contains a single string, the string is parsed. Otherwise it must be a flat array of key-value pairs.

=item C<key_prefix> => STR (optional, default: "")

Prefix prepended to the keys.

=item C<quote> => BOOL (optional, default: false)

If true, the values are quoted.

=back

=head2 $pdata->add_entry(@entries)

=head2 @values = $pdata->get_resolved_entry($key)

Get the values from the PKL. It resolves inheritance and evaluates code-ref values.
If there is no such key in C<$pdata> or any of its ancestors, it returns an empty list.

=head2 $pdata->each_resolved_entry($code)

Iterate over resolved PKL entries.

    $code->($key, $resolved_values_array_ref)

=head2 $pdata->delete_entry($key)

=head2 $exists = $pdata->has_own_entry($key)

=head2 $pdata->set_parent($parent)

=head2 $parent = $pdata->parent()

=head1 AUTHOR

Toshio Ito, C<< <toshioito at cpan.org> >>


=cut
