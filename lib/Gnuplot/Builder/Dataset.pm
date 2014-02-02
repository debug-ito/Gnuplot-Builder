package Gnuplot::Builder::Dataset;
use strict;
use warnings;

1;

__END__

=pod

=head1 NAME

Gnuplot::Builder::Dataset - Object-oriented builder for gnuplot dataset

=head1 SYNOPSIS

    use Gnuplot::Builder::Script;
    use Gnuplot::Builder::Dataset;
    
    my $builder = Gnuplot::Builder::Script->new;
    
    my $unit_scale = 0.001;
    my $file_data = Gnuplot::Builder::Dataset->new_file("sampled_data1.dat");
    $file_data->set_option(
        using => sub { "1:(\$2 * $unit_scale)" },
        title => '"sample 1"',
        with  => 'linespoints lw 2'
    );
    
    my $another_file_data = $file_data->new_child;
    $another_file_data->set_file("sampled_data2.dat");    ## override parent's setting
    $another_file_data->setq_option(title => "sample 2"); ## override parent's setting
    
    $builder->plot($file_data, $another_file_data);


=head1 DESCRIPTION

L<Gnuplot::Builder::Dataset> is a builder object for gnuplot dataset (the data to be plotted).

Like L<Gnuplot::Builder::Script>, this module stores dataset parameters in a hash-like structure.
It supports lazy evaluation and prototype-based inheritance, too.

=head2 Data Model

A L<Gnuplot::Builder::Dataset> consists of three attributes; C<< the source, the options and the inline data >>.

    plot "source.dat" using 1:2 title "file" with lp, \
         f(x) title "function" with lines, \
         "-" using 1:2 title "inline" with lp
    10 20
    15 11
    20 43
    25 32
    end

=over

=item *

The source is the first part of the dataset parameters.
In the above example, C<"source.dat">, C<f(x)> and C<"-"> are the sources.

=item *

The options are the rest of the dataset parameters after the source.
In the above example, C<< using 1:2 title "file" with lp >> is the options of the first dataset.

L<Gnuplot::Builder::Dataset> stores the options in a hash-like data structure.

=item *

The inline data is the data given after the "plot" command.
In the above example, only the third dataset has its inline data.

=back


=head1 CLASS METHODS

=head2 $dataset = Gnuplot::Builder::Dataset->new($source, @set_option_args)

=head2 $dataset = Gnuplot::Builder::Dataset->new_file($filename, @set_option_args)

=head2 $dataset = Gnuplot::Builder::Dataset->new_data($data_provider, @set_option_args)

=head1 OBJECT METHODS - BASICS

=head2 $string = $dataset->to_string()

=head2 $string = $dataset->params_string()

=head1 OBJECT METHODS - SOURCE

Methods about the source of the dataset.

=head2 $dataset = $dataset->set_source($source_str)

=head2 $dataset = $dataset->setq_source($source_str)

=head2 $dataset = $dataset->set_file($source_filename)

=head2 $source = $dataset->get_source()

=head2 $dataset = $dataset->delete_source()

=head1 OBJECT METHODS - OPTIONS

Methods about the options of the dataset.

=head2 $dataset = $dataset->set_option($opt_name => $opt_value, ...)

=head2 $dataset = $dataset->setq_option($opt_name => $opt_value, ...)

=head2 $opt_value = $dataset->get_option($opt_name)

=head2 $dataset = $dataset->delete_option($opt_name, ...)


=head1 OBJECT METHODS - INLINE DATA

=head2 $dataset = $dataset->set_data($data_provider)

=head2 $dataset = $dataset->write_data_to($writer)

=head2 $dataset = $dataset->delete_data()

=head1 OBJECT METHODS - INHERITANCE

=head2 $dataset = $dataset->set_parent($parent_dataset)

=head2 $parent_dataset = $dataset->parent()

=head2 $child_dataset = $dataset->new_child()

=head1 OVERRIDES

When you evaluate a C<$dataset> as a string, it executes C<< $dataset->to_string() >>. That is,

    "$dataset" eq $dataset->to_string;


=head1 SEE ALSO

L<Gnuplot::Builder::Script>

=head1 AUTHOR

Toshio Ito

=cut
