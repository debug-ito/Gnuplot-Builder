package Gnuplot::Builder::Script;
use strict;
use warnings;

1;

__END__

=pod

=head1 NAME

Gnuplot::Builder::Script - Object-oriented builder for gnuplot script

=head1 SYNOPSIS

    use Gnuplot::Builder::Script;
    use Gnuplot::Builder::Dataset;
    
    my $dataset = Gnuplot::Builder::Dataset->new(source => 'f(x)');
    
    my $builder = Gnuplot::Builder::Script->new(<<EOT);
    terminal = png size 500,500 enhanced
    grid     = x y
    xrange   = [-10:10]
    yrange   = [-1:1]
    xlabel   = x offset 0,1
    ylabel   = y offset 1,0
    output   = "sin_wave.png"
    EOT
    
    $builder->unset('key');
    $builder->def('f(x) = sin(pi * x)');
    $builder->plot($dataset);                ## output sin_wave.png
    
    my $child = $builder->child;
    $child->def('f(x) = cos(pi * x)');      ## override parent's setting
    $child->set('output = "cos_wave.png"'); ## override parent's setting
    $child->plot($dataset);                 ## output cos_wave.png


=head1 DESCRIPTION

L<Gnuplot::Builder::Script> is a builder object for a gnuplot script.

The advantages of this module over just printing script text are:

=over

=item *

It keeps option settings and definitions in a hash-like data structure.
So you can change those items partially.

=item *

It accepts subroutine references for script sentences, option settings and definitions.
They are evaluated every time it builds the script.

=item *

It supports prototype-based inheritance similar to JavaScript objects.
A child builder can override its parent's settings.

=back

=head1 CLASS METHODS

=head2 $builder = Gnuplot::Builder::Script->new(@set_args)

The constructor. It creates an empty builder.

Arguments C<@set_args> are directly given to C<set()> method.

=head1 OBJECT METHODS - BASICS

Most object methods return the object itself, so that you can chain those methods.

=head2 $script = $builder->to_string()

Build and return the gnuplot script.


=head2 $builder = $buider->add(@sentences)

Add gnuplot script sentences to the C<$builder>.

This is a low-level method. B<< In most cases you should use C<set()> and C<def()> methods below. >>

C<@sentences> is a list of strings and/or subroutine references.
A subroutine reference is evaluated in list context when it builds the script.

Example:

    $builder->add(<<'EOT');
    set title "sample"
    set xlabel "iteration"
    EOT
    my $unit = "sec";
    $builder->add(sub { qq{set ylabel "Time [$unit]"} });

=head1 OBJECT METHODS - GNUPLOT OPTIONS

Methods to manipulate gnuplot options (the "set" and "unset" commands).

=head2 $builder = $builder->set_option($opt_name => $opt_value, ...)

Set a gnuplot option named C<$opt_name> to C<$opt_value>.
You can set more than one name-value pairs.

C<$opt_value> is either C<undef>, a string, an array-ref of strings or a subroutine reference.

=over

=item *

If C<$opt_value> is C<undef>, the "unset" command is generated for the option.

=item *

If C<$opt_value> is a string, the option is set to that string.

=item *

If C<$opt_value> is an array-ref, the "set" command is repeated for each element in it.
If the array is empty, no "set" or "unset" command is generated.

    $builder->set_option(
        terminal => 'png size 200,200',
        key      => undef,
    );
    $builder->to_string();
    ## => set terminal png size 200,200
    ## => unset key
        
    $builder->set_option(
        arrow => ['1 from 0,0 to 0,1', '2 from 100,0 to 0,100']
    );
    $builder->to_string();
    ## => set terminal png size 200,200
    ## => unset key
    ## => set arrow 1 0,0 to 0,1
    ## => set arrow 2 from 100,0 to 0,100

=item *

If C<$opt_value> is a subroutine reference,
it is evaluated in list context when the C<$builder> builds the script.

    @values = $opt_value->($builder, $opt_name)

The C<$builder> and C<$opt_name> are given to the subroutine reference.

Then, the option is generated as if C<< $opt_name => \@values >> was set.

=back

=head2 $builder = $builder->set(@opt_scripts)

=head2 @opt_values = $builder->get_option($opt_name)

=head2 $builder = $builder->delete_option($opt_name, ...)

TODO: "delete" vs. "set empty array" in child builder.

=head1 OBJECT METHODS - GNUPLOT DEFINITIONS

Methods to manipulate user-defined variables and functions.

=head2 $builder = $builder->set_definition($def_name => $def_value, ...)

=head2 $builder = $builder->def(@def_scripts)

=head2 @def_values = $builder->get_definition($def_name)

=head2 $builder = $builder->delete_definition($def_name, ...)

=head1 OBJECT METHODS - INHERITANCE

Methods about object inheritance.

=head2 $child_builder = $builder->child()

=head2 $parent_builder = $builder->parent()

=head1 OBJECT METHODS - PLOTTING

=head1 OVERRIDES

When you evaluate a C<$builder> as a string, it executes C<< $builder->to_string() >>. i.e.

    "$builder" eq $builder->to_string;

=head1 AUTHOR

Toshio Ito, C<< <toshioito at cpan.org> >>

=cut
