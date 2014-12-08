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

our @EXPORT_OK = qw(using);

our $USING = Gnuplot::Builder::JoinDict->new(
    separator => ":",
    content => [
        map { $_ => undef }
        qw(
              -x -y
              -y1 -y2
              -z
              -t
              -r -g -b -a
              -string
              -xdelta -ydelta -zdelta -xlow -xhigh -ylow -yhigh
              -date -open -low -high -close
              -box_min -whisker_min -whisker_high -box_high
              -x_width
              -boxplot_factor
              -radius -start_angle -end_angle
              -major_diam -minor_diam -angle
              -value
              -pointsize -arrowstyle
              -linecolor
      )
    ]
);

sub using {
    return $USING->set(@_);
}


1;
__END__

=pod

=head1 NAME

Gnuplot::Builder::Template - predefined Gnuplot::Builder objects as templates

=head1 SYNOPSIS

    use Gnuplot::Builder::Dataset;
    use Gnuplot::Builder::Template qw(using every);
    
    my $dataset = Gnuplot::Builder::Dataset->new_data("sample.dat");
    $dataset->set(
        using => using(
            -x => 1, -xlow => 2, -xhigh => 3,
            -y => 4, -ylow => 5, -yhigh => 6
        ),
        every => every(
            -start_point => 1, -end_point => 50
        ),
        with => "xyerrorbars",
    );
    "$dataset";  ## => 'sample.dat' using 1:4:2:3:5:6 every ::1:50 with xyerrorbars
    
    $dataset->get_option("using")->get("-xlow");         ## => 2
    $dataset->get_option("every")->get("-start_point");  ## => 1

=head1 DESCRIPTION

B<< This module is experimental. API and object specification may be changed in the future. >>

L<Gnuplot::Builder::Template> provides template objects useful to build some gnuplot script elements.
These objects are structured, so you can modify their parameters partially.

=head1 EXPORTABLE FUNCTIONS

The following functions are exported only by request.

=head2 $using_joindict = using(@key_value_pairs)

Create and return a L<Gnuplot::Builder::JoinDict> object useful for "using" parameters.
Actually it's just a short for C<< $Gnuplot::Builder::Template::USING->set(@key_value_pairs) >>.

=head2 $every_joindict = every(@key_value_pairs)

=head1 PACKAGE VARIABLES

=head2 $USING

=head2 $EVERY

TODO: template package variables

=head1 AUTHOR

Toshio Ito, C<< <toshioito at cpan.org> >>

=cut
