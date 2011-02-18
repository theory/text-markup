#!/usr/bin/env perl -w

use strict;
use warnings;
use Test::More 0.96;
use File::Spec::Functions qw(tmpdir catfile);
use Text::Markup;
use Test::File;

sub slurp($) {
    my $file = shift;
    open my $fh, '<:encoding(utf-8)', $file or die "Cannot open $file: $!\n";
    local $/;
    return <$fh>;
}

my (@loaded, @unlink);
END { unlink $_ for @unlink };

while (my $data = <DATA>) {
    next if /^#/;
    chomp $data;
    my ($format, $module, $req, @exts) = split /,/ => $data;
    subtest "Testing $format format" => sub {
        eval "use $req; 1;";
        plan skip_all => "$module not installed" if $@;
        plan tests => @exts + 7;
        use_ok $module or die;

        push @loaded => $format;
        is_deeply [Text::Markup->formats], \@loaded,
            "$format should be loaded";

        my $parser = new_ok 'Text::Markup';
        for my $ext (@exts) {
            is $parser->guess_format("foo.$ext"), $format,
                "Should guess that .$ext extension is $format";
        }

        my $outfile = catfile tmpdir, "$format-$$.html";
        push @unlink => $outfile;
        file_not_exists_ok $outfile, "$format-$$.html should not yet exist";

        ok $parser->parse(
            from   => catfile('t', 'markups', "$format.txt"),
            to     => $outfile,
            format => $format,
        ), "Parse $format file";

        file_exists_ok $outfile, "$format-$$.html should now exist";
        is slurp $outfile, slurp catfile('t', 'html', "$format.html"),
            "The $format-generated HTML should be correct"
    }
}

done_testing;

__DATA__
# Format,Format Module,Required Module,extensions
markdown,Text::Markup::Markdown,Text::Markdown 1.000004,md,mkdn,mkd,mdown,markdown
