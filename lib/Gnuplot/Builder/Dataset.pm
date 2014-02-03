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

The general-purpose constructor. All arguments are optional.
C<$source> is the source string of this dataset. C<@set_option_args> are the option settings.

This method is equivalent to C<< new()->set_source($source)->set_option(@set_option_args) >>.

=head2 $dataset = Gnuplot::Builder::Dataset->new_file($filename, @set_option_args)

The constructor for datasets whose source is a file.
C<$filename> is the name of the source file.

This method is equivalent to C<< new()->set_file($filename)->set_option(@set_option_args) >>.

=head2 $dataset = Gnuplot::Builder::Dataset->new_data($data_provider, @set_option_args)

The constructor for datasets that have inline data.
C<$data_provider> is the source of the inline data.

This method is equivalent to C<< new()->set_file('-')->set_data($data_provider)->set_option(@set_option_args) >>.

=head1 OBJECT METHODS - BASICS

=head2 $string = $dataset->to_string()

Build and return the dataset parameter string.
It does not contain the inline data.

=head2 $string = $dataset->params_string()

Alias of C<to_string()> method. It's for plotting methods of L<Gnuplot::Builder::Script>.

=head1 OBJECT METHODS - SOURCE

Methods about the source of the dataset.

=head2 $dataset = $dataset->set_source($source)

Set the source of the C<$dataset> to C<$source>.

C<$source> is either a string or code-ref.
If C<$source> is a string, that string is used for the source.

If C<$source> is a code-ref, it is evaluated in list context when C<$dataset> builds the parameters.

    ($source_str) = $source->($dataset)

C<$dataset> is passed to the code-ref.
The first element of the result (C<$source_str>) is used for the source.

=head2 $dataset = $dataset->setq_source($source)

Same as C<set_source()> method except that the eventual source string is quoted.
Useful for setting the file name of the dataset.

=head2 $dataset = $dataset->set_file($source_filename)

Alias of C<setq_source()> method.

=head2 $source_str = $dataset->get_source()

Return the source string of the C<$dataset>.

If a code-ref is set for the source, it is evaluated and the result is returned.

If the source is not set in the C<$dataset>, it returns its parent's source string.
If none of the ancestors doesn't have the source, it returns C<undef>.

=head2 $dataset = $dataset->delete_source()

Delete the source setting from the C<$dataset>.

After the source is deleted, C<get_source()> method will search the parent for the source string.

=head1 OBJECT METHODS - OPTIONS

Methods about the options of the dataset.

=head2 $dataset = $dataset->set_option($opt_name => $opt_value, ...)

Set the dataset option named C<$opt_name> to C<$opt_value>.
You can specify more than one pairs of C<$opt_name> and C<$opt_value>.

C<$opt_name> is the name of the option (e.g. "using" and "every").

C<$opt_value> is either C<undef>, a string or a code-ref.

=over

=item *

If C<$opt_value> is C<undef>, the whole option (including the name) won't appear in the parameters it builds.

=item *

If C<$opt_value> is a string, the option is set to that string.

=item *

If C<$opt_value> is a code-ref, that is evaluated in list context when the C<$dataset> builds the parameters.

    ($opt_value_str) = $opt_value->($dataset, $opt_name)

C<$dataset> and C<$opt_name> are passed to the code-ref.

Then, the first element in the result (C<$opt_value_str>) is used for the option value.
You can return C<undef> to disable the option.

=back

The options are stored in a hash-like structure, so you can change them individually.
Even if you change an option value, its order is unchanged.

    my $scale = 0.001;
    $dataset->set_file('dataset.csv');
    $dataset->set_option(
        every => undef,
        using => sub { qq{1:(\$2/$scale)} },
        title => '"data"',
        with  => 'lines lw 2'
    );
    $dataset->to_string();
    ## => 'dataset.csv' using 1:($2/0.001) title "data" with lines lw 2
    
    $dataset->set_option(
        title => undef,
        every => '::1',
    );
    $dataset->to_string();
    ## => 'dataset.csv' every ::1 using 1:($2/0.001) with lines lw 2

You are free to pass any string to C<$opt_name> in any order,
but this module does not guarantee it's syntactically correct.

    $bad_dataset->set_option(
        lw => 4,
        w  => "lp",
        ps => "variable",
        u  => "1:2:3"
    );
    $bad_dataset->to_string();
    ## => "hoge" lw 4 w lp ps variable u 1:2:3
    
    ## The above parameters are invalid!!!
    
    $good_dataset->set_option(
        u  => "1:2:3",
        w  => "lp",
        lw => 4,
        ps => "variable"
    );
    $good_dataset->to_string();
    ## => "hoge" u 1:2:3 w lp lw 4 ps variable


Some dataset options such as "matrix" and "volatile" don't have arguments.
You can set such options like this.

    $dataset->set_option(
        matrix   => "",    ## enable
        volatile => undef, ## disable
    );

Or, you can even write like this.

    $dataset->set_option(
        "" => "matrix"
    );

There is more than one way to do it.

=head2 $dataset = $dataset->setq_option($opt_name => $opt_value, ...)

Same as C<set_option()> method except that the eventual option value is quoted.
This is useful for setting "title" and "index".

    $dataset->setq_option(
        title => "Sample A's result",
    );
    $dataset->to_string();
    ## => "hoge" title 'Sample A''s result'
    
    $dataset->setq_option(
        title => ""  ## same effect as "notitle"
    );
    $dataset->to_string();
    ## => "hoge" title ''


=head2 $opt_value = $dataset->get_option($opt_name)

Return the option value for the name C<$opt_name>.

If a code-ref is set to the C<$opt_name>, it's evaluated and its result is returned.

If the option is not set in C<$dataset>, the value of its parent is returned.
If none of the ancestors doesn't have the option, it returns C<undef>.

=head2 $dataset = $dataset->delete_option($opt_name, ...)

Delete the option from the C<$dataset>.
You can specify more than one C<$opt_name>s.

Note the difference between C<delete_option($opt_name)> and C<< set_option($opt_name => undef) >>.
C<delete_option()> removes the option setting from the C<$dataset>,
so it's up to its ancestors to determine the value of the option.
On the other hand, C<set_option()> always overrides the parent's setting.

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
