#!/usr/bin/env perl
use 5.12.0;
use autodie;

my $f = shift;

open my $in, "<", $f;
open my $out, ">", "$f.tmp";

my $cont = join '', <$in>;

$cont =~ s[
    \b
    (?<func>(?:error|die|die_errno|warning|fprintf|printf|refresh_index))
    (?<w>\ *)
    \( (?<cont>.*?) \);
][
munge($+{func}, $+{w}, $+{cont});
]exgs;

sub munge {
    my ($func, $w, $cont) = @_;

    if ($cont =~ /\s*_\(/s) {
        #warn "Skipping <$cont>";
        goto end;
    }

    if ($cont =~ /\Q"%s %s... %s\n"/ or
        $cont =~ /\Q"# %s\n"/ or
        $cont =~ /\Q"#\n"/ or
        $cont =~ /\Q"%s"/ or
        $cont =~ /\Q"\n"/ or
        $cont =~ /\Q"-%d-g%s"/ or
        $cont =~ /\Q" %-11s %8d %s\n"/ or
        $cont =~ /\Q"%s %s\n"/ or
        $cont =~ /\Q"%s\t%s\t%s"/ or
        $cont =~ /\Q" %s\n"/ or
        $cont =~ /\Q"%s%s\n"/ or
        $cont =~ /\Q"%.*s"/ or
        $cont =~ /\Q" %s"/ or
        $cont =~ /\Q"\t%s\n"/ or
        $cont =~ /\Q" * [%s] %s\n"/ or
        $cont =~ /\Q"%s\t%s\n"/ or
        $cont =~ /\Q" %.*s\n"/ or
        $cont =~ /\Q"%-15s "/ or
        $cont =~ /\Q"\n    "/ or
        $cont =~ /\Q"%s=%s\n"/ or
        $cont =~ /\Q"[%"PRIuMAX"] "/
        or $cont =~ /\Q" %s%c"/
        or $cont =~ /\Q"%s%c"/
        or $cont =~ /\Q"%s -> "/
        or $cont =~ /\Q"%s %s%c"/
        or $cont =~ /\Q"%stag %s%s\n"/
        or $cont =~ /\Q"%stree %s%s\n\n"/
        or $cont =~ /\Q"-- \n%s\n\n"/
        or $cont =~ /\Q"\n--%s%s--\n\n\n"/
        or $cont =~ /\Q"%c %s %s\n"/
        or $cont =~ /\Q"%c %s\n"/
        or $cont =~ /\Q".\n"/
        or $cont =~ /\Q"'%s': %s"/
        or $cont =~ /\Q"rm '%s'\n"/
        or $cont =~ /\Q"git rm: '%s'"/
        or $cont =~ /\Q"%6d\t%s\n"/
        or $cont =~ /\Q"%s (%d):\n"/
        or $cont =~ /\Q"      %s\n"/
    ) {
        #warn "Skipping pure format <$cont>";
        goto end;
    }

  munge:
        $cont =~ s[(?<!_\()"(.*)"][
            $1 ~~ [ "%s\\n" ]
            ? qq["$1"]
            : qq[_("$1")]
        ]es;
  end:

    return "$func$w($cont);";
}

print $out $cont;
close $_ for $in, $out;
rename "$f.tmp", $f;
