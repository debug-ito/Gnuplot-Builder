package Gnuplot::Builder::PartiallyKeyedList;
use strict;
use warnings;
use Carp;
use List::DoubleLinked;


sub new {
    my ($class) = @_;
    my $self = bless {
        list => List::DoubleLinked->new(),
        iterator_for => {},
    }, $class;
    return $self;
}

sub set {
    my ($self, $key, $value) = @_;
    croak "key must be defined" if not defined $key;
    my $existing_iterator = $self->{iterator_for}{$key};
    if(!defined($existing_iterator)) {
        $self->{list}->push([$key, $value]);
        ## $self->{iterator_for}{$key} = $self->{list}->end;

        ## end() method is fuckin' buggy.
        use List::DoubleLinked::Iterator;
        $self->{iterator_for}{$key} = List::DoubleLinked::Iterator->new($self->{list}, $self->{list}->{tail});
        
    }else {
        my $entry = $existing_iterator->get;
        $entry->[1] = $value;
    }
}

sub get {
    my ($self, $key) = @_;
    croak "key must be defined" if not defined $key;
    my $existing_iterator = $self->{iterator_for}{$key};
    return defined($existing_iterator) ? $existing_iterator->get->[1] : undef;
}

sub exists {
    my ($self, $key) = @_;
    croak "key must be defined" if not defined $key;
    return defined($self->{iterator_for}{$key});
}

sub delete {
    my ($self, $key) = @_;
    croak "key must be defined" if not defined $key;
    my $existing_iterator = $self->{iterator_for}{$key};
    return undef if not defined $existing_iterator;
    my $value = $existing_iterator->get->[1];
    $existing_iterator->remove();
    delete $self->{iterator_for}{$key};
    return $value;
}

sub add {
    my ($self, $entry) = @_;
    $self->{list}->push([undef, $entry]);
}

sub each {
    my ($self, $code) = @_;
    croak "code must be a code-ref" if !defined($code) || ref($code) ne "CODE";

    ## iteration looks ugly... https://github.com/Leont/list-doublelinked/issues/2
    my $size = $self->{list}->size;
    my $iterator;
    for (1..$size) {
        $iterator = defined($iterator) ? $iterator->next : $self->{list}->begin;
        $code->(@{$iterator->get});
    }
}

sub merge {
    my ($self, $another) = @_;
    croak "another_pkl must be an object" if !defined($another) || !ref($another);
    $another->each(sub {
        my ($key, $value) = @_;
        if(defined($key)) {
            $self->set($key, $value);
        }else {
            $self->add($value);
        }
    });
}

1;

__END__

=pod

=head1 NAME

Gnuplot::Builder::PartiallyKeyedList - a list part of which you can randomly access

=head1 SYNOPSIS

    use Gnuplot::Builder::PartiallyKeyedList;
    
    sub print_pkl {
        my $pkl = shift;
        $pkl->each(sub {
            my ($key, $value) = @_;
            printf('%s : %s'."\n", (defined($key) ? $key : "-"), $value);
        });
    }
    
    my $pkl = Gnuplot::Builder::PartiallyKeyedList->new;
    
    $pkl->add("1");
    $pkl->set(a => 2);
    $pkl->add(3);
    $pkl->add(4);
    $pkl->set(b => 5);
    print_pkl $pkl;
    ## => - : 1
    ## => a : 2
    ## => - : 3
    ## => - : 4
    ## => b : 5
    
    $pkl->set(a => "two");
    print_pkl $pkl;
    ## => - : 1
    ## => a : two
    ## => - : 3
    ## => - : 4
    ## => b : 5
    
    my $another = Gnuplot::Builder::PartiallyKeyedList->new;
    $another->add(6);
    $another->set(b => "five");
    $pkl->merge($another);
    print_pkl $pkl;
    ## => - : 1
    ## => a : two
    ## => - : 3
    ## => - : 4
    ## => b : five
    ## => - : 6

=head1 DESCRIPTION

This is an internal module for L<Gnuplot::Builder> distribution.
However it's general enough for separate distribution.
If you are interested in it, just contact me.

L<Gnuplot::Builder::PartiallyKeyedList> is similar to L<Tie::IxHash>.
It maintains an ordered associative array.
The difference is that it can contain entries without keys.
So essentially, it's a list in which some entries have keys.

The data model of this module is depicted below.

    You can access all entries sequentially.
     |
     | [entry 0]
     | [entry 1] key: a       <--- You can access some of
     | [entry 2]                   the entries randomly.
     | [entry 3] key: hoge    <---
     | [entry 4] key: foobar  <---
     | [entry 5]
     v

=head1 CLASS METHODS

=head2 $pkl = Gnuplot::Builder::PartiallyKeyedList->new()

The constructor. It creates an empty list.

=head1 OBJECT METHODS

=head2 $pkl->set($key, $value)

Set the value for the C<$key> to C<$value>.
C<$key> must be a defined string.

If C<$key> is already set in C<$pkl>, the existing value is replaced.
If C<$key> doesn't exist in C<$pkl>, a new keyed entry is added.

=head2 $value = $pkl->get($key)

Get the value for the C<$key>.

If C<$key> doesn't exist in C<$pkl>, it returns C<undef>.

=head2 $does_exist = $pkl->exists($key)

Return true if C<$key> exists in C<$pkl>. False otherwise.

=head2 $value = $pkl->delete($key)

Delete the value for the C<$key> from the C<$pkl>.

If C<$key> exists, it returns the value for the C<$key>.
If C<$key> doesn't exist, it returns C<undef>.

=head2 $pkl->add($entry)

Add a non-keyed entry to the C<$pkl>.

=head2 $pkl->each($code)

Iterate over all the entries in C<$pkl> from the head,
and execute the C<$code> for each entry.

C<$code> is a code-ref that is called for each entry.

    $code->($key, $value)

C<$code> is passed two arguments, C<$key> and C<$value>.
For non-keyed entry, C<$key> is C<undef>.
For keyed entry, C<$key> is the key of the entry.
C<$value> is the value of the entry in both cases.

=head2 $pkl->merge($another_pkl)

Merge all entries in C<$another_pkl> into C<$pkl>.
This is a mutator method.

Non-keyed entries in C<$another_pkl> are just added to C<$pkl>.

Keyed entries in C<$another_pkl> replace existing entries in C<$pkl>.
If the key doesn't exist in C<$pkl>, the entry is added.

=head1 AUTHOR

Toshio Ito, C<< <toshioito at cpan.org> >>

=cut
