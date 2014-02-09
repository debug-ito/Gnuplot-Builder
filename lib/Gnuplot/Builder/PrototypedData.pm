package Gnuplot::Builder::PrototypedData;
use strict;
use warnings;
use Gnuplot::Builder::PartiallyKeyedList;

sub new {
    my ($class) = @_;
    my $self = bless {
        list => Gnuplot::Builder::PartiallyKeyedList->new,
        attributes => {},
    }, $class;
    return $self;
}

sub list { $_[0]->{list} }


## Common data structure for Script and Dataset. It has a
## PartiallyKeyedList and optional named attributes. It implements
## prototype-based inheritance.

## should it have setq()? or setq() can be implemented as a common wrapper function.

## should it have a method to get normalized values (code-refs are evalulated)?

1;
