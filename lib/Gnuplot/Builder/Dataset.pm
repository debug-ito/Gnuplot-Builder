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

=head1 CLASS METHODS

=head1 OBJECT METHODS

=head2 $string = $dataset->params_string()

=head2 $dataset = $dataset->write_data_to($writer)

=head1 OVERRIDES

=head1 SEE ALSO

L<Gnuplot::Builder::Script>

=head1 AUTHOR

Toshio Ito


=cut
