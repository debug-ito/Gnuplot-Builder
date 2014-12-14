package Gnuplot::Builder::Template;
use strict;
use warnings;

## TODO:
## - how should we maintain backward-compatibility??
## - can we assume this module provides JoinDict only??
## 個別の関数ごとに互換性条項を定めるか？それもなー。
## 
## ロード時のimportオプションでバージョンを指定する？
## それでもいいけど、それならバージョンサブモジュールがあったほうがいいような。
## Exporterをそのまんま使えなくなるし、importなしで使った場合に変なことになる。
## 
## 間違ってなければいいんだけど。あとはgnuplot側のバージョンアップに追従する必要はある。
## 別の関数、別のテンプレートオブジェクトを作るか？ using2とか。それがいいか。
## 
## あとはキー名のルール。テンプレートにユーザがパラメータのせて、
## その後バージョンアップでそのパラメータがテンプレートに入ったら順番変わってしまう。
## キーの追加をしないってポリシーはさすがにダルいよな
## 
## ちなみにDBIではattribute nameとして以下の規則をおいている。
## 
## - UPPER_CASE: standard
## - MixedCase: DBI
## - lower_case: driver specific
## 
## あるいはハイフンから始まるようにしてもいいかも。
## でもstart_pointなんかだとハイフンとアンダースコアが混ざることになる。
## ハイフンが語中に混ざる場合、ベアワードではキーとして認識されない。
## それは使いづらいなあ。
## 
## まあ、頭にハイフン、中間はアンダースコア、が妥当だと思う。
## MixedCaseは変換ルールが曖昧になりがちだし、UPPERCASEも打ちづらい。

use Exporter 5.57 qw(import);
use Gnuplot::Builder::JoinDict;

our @EXPORT_OK = qw(gusing);

our $USING = Gnuplot::Builder::JoinDict->new(
    separator => ":",
    content => [
        map { substr($_, 0, 1) eq "-" ? ( $_ => undef ) : () }
        qw(
    USE CASES        | KEYS
    =================+==============================================
                     | -x -y
    "filledcurves"   | -y1 -y2
                     | -z
    polar            | -t
    "image"          | -value
    smooth kdensity  | -weight -bandwidth
    "rgbalpha"       | -r -g -b -a
    "labels"         | -string -label
    "vectors"        | -xdelta -ydelta -zdelta
    "xerrorbars"     | -xlow -xhigh
    "yerrorbars"     | -ylow -yhigh
    "financebars"    | -date -open -low -high -close
    "candlesticks"   | -box_min -whisker_min -whisker_high -box_high
    "boxes"          | -x_width
    "boxplot"        | -boxplot_factor
    "circles"        | -radius -start_angle -end_angle
    "ellipses"       | -major_diam -minor_diam -angle
    variable style   | -pointsize -arrowstyle -linecolor
      )
    ]
);

sub gusing {
    return $USING->set(@_);
}


1;
__END__

=pod

=head1 NAME

Gnuplot::Builder::Template - predefined Gnuplot::Builder objects as templates

=head1 SYNOPSIS

    use Gnuplot::Builder::Dataset;
    use Gnuplot::Builder::Template qw(gusing gevery);
    
    my $dataset = Gnuplot::Builder::Dataset->new_data("sample.dat");
    $dataset->set(
        using => gusing(
            -x => 1, -xlow => 2, -xhigh => 3,
            -y => 4, -ylow => 5, -yhigh => 6
        ),
        every => gevery(
            -start_point => 1, -end_point => 50
        ),
        with => "xyerrorbars",
    );
    "$dataset";  ## => 'sample.dat' using 1:4:2:3:5:6 every ::1:50 with xyerrorbars
    
    $dataset->get_option("using")->get("-xlow");         ## => 2
    $dataset->get_option("every")->get("-start_point");  ## => 1

=head1 DESCRIPTION

B<< This module is in alpha state. API and object specification may be changed in the future. >>

L<Gnuplot::Builder::Template> provides template objects useful to build some gnuplot script elements.
These objects are structured, so you can modify their parameters partially.

=head1 EXPORTABLE FUNCTIONS

The following functions are exported only by request.

=head2 $using_joindict = gusing(@key_value_pairs)

Create and return a L<Gnuplot::Builder::JoinDict> object useful for "using" parameters.
Actually it's just a short for C<< $Gnuplot::Builder::Template::USING->set(@key_value_pairs) >>.

The L<Gnuplot::Builder::JoinDict> object returned by this function has predifined keys.
By default, values for the predefined keys are all C<undef>.

The predefined keys are listed in the right column of the following table.

    USE CASES        | KEYS
    =================+==============================================
                     | -x -y
    "filledcurves"   | -y1 -y2
                     | -z
    polar            | -t
    "image"          | -value
    smooth kdensity  | -weight -bandwidth
    "rgbalpha"       | -r -g -b -a
    "labels"         | -string -label
    "vectors"        | -xdelta -ydelta -zdelta
    "xerrorbars"     | -xlow -xhigh
    "yerrorbars"     | -ylow -yhigh
    "financebars"    | -date -open -low -high -close
    "candlesticks"   | -box_min -whisker_min -whisker_high -box_high
    "boxes"          | -x_width
    "boxplot"        | -boxplot_factor
    "circles"        | -radius -start_angle -end_angle
    "ellipses"       | -major_diam -minor_diam -angle
    variable style   | -pointsize -arrowstyle -linecolor

We also show typical use cases for the keys in the left column of the table.

Note that these keys are in the same order as shown in the table,
so you would always get the "using" parameter in the correct order.

For example,

    my $using = gusing(-y => 5, -x => 3);
    "$using"  ## => 3:5

OK, that doesn't seem very useful, but how about this?

    my $using = gusing(-x => 1,
                       -whisker_min => 2, -box_min => 3,
                       -box_high => 4, -whisker_high => 5);
    "$using";  ## 1:3:2:5:4

Now you don't have to remember the complicated "using" spec of "candlesticks" style.
Just give the parameters with the keys,
and the L<Gnuplot::Builder::JoinDict> object arranges them in the correct order.

You can add your own key-value pairs to the parameters. For example,

    my $using = gusing(-x => 1, -y => 2, -x_width => "(0.7)", tics => "xticlabels(3)");
    "$using";  ## 1:2:(0.7):xticlabels(3)

Keys that start with C<"-"> are preserved, so you should avoid using them for your own keys.

C<gusing()> function uses C<$Gnuplot::Builder::Template::USING> package variable as the template.
You can customize it.

Note that some keys may be added to the template in the future. See L</COMPATIBILITY> for detail.

=head2 $every_joindict = gevery(@key_value_pairs)

=head1 PACKAGE VARIABLES

=head2 $USING

=head2 $EVERY

TODO: template package variables

=head1 COMPATIBILITY

B<< This module is still in alpha, so any part of this module (including this section) may be changed in the future. For now you can think of this section as a draft of our compatibility policy. >>

This section describes what part of this module may be changed in the future releases and what part is NOT gonna be changed.

=head2 gusing() and gevery()

=over

=item *

No predefined key will be removed. (although some of them may get deprecated)

=item *

Predefined keys may be added/inserted at any part in the current list of predefined keys.

=item *

All predefined keys start with C<"-">.

=item *

The relative order of predefined keys will always be preserved.

=back

=head1 AUTHOR

Toshio Ito, C<< <toshioito at cpan.org> >>

=cut
