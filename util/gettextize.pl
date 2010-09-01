#!/usr/bin/env perl
use 5.12.0;
use autodie;

my $f = shift;

open my $in, "<", $f;
open my $out, ">", "$f.tmp";

my $cont = join '', <$in>;

$cont =~ s[
    \b
    (?<func>(?:die|die_errno|warning|fprintf|printf|refresh_index))
    (?<w>\ *)
    \( (?<cont>.*?) \);
][
munge($+{func}, $+{w}, $+{cont});
]exgs;

sub munge {
    my ($func, $w, $cont) = @_;

    $cont =~ s[(?<!_\()"(.*)"][
        $1 ~~ [ "%s\\n" ]
        ? qq["$1"]
        : qq[_("$1")]
    ]es;

    return "$func$w($cont);";
}

print $out $cont;
close $_ for $in, $out;
rename "$f.tmp", $f;
