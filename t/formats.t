#!/usr/bin/env perl -w

use strict;
use warnings;
use Test::More 0.96;
use Text::Markup;
use File::Spec::Functions qw(catfile);

sub slurp($) {
    my $file = shift;
    open my $fh, '<:encoding(utf-8)', $file or die "Cannot open $file: $!\n";
    local $/;
    return <$fh>;
}

my @loaded;
while (my $data = <DATA>) {
    next if $data =~ /^#/;
    chomp $data;
    my ($format, $module, $req, @exts) = split /,/ => $data;
    subtest "Testing $format format" => sub {
        eval "use $req; 1;";
        plan skip_all => "$module not installed" if $@;
        plan tests => @exts + 4;
        use_ok $module or next;

        push @loaded => $format;
        is_deeply [Text::Markup->formats], \@loaded,
            "$format should be loaded";

        my $parser = new_ok 'Text::Markup';
        for my $ext (@exts) {
            is $parser->guess_format("foo.$ext"), $format,
                "Should guess that .$ext extension is $format";
        }

        is $parser->parse(
            file   => catfile('t', 'markups', "$format.txt"),
            format => $format,
        ), slurp catfile('t', 'html', "$format.html"),"Parse $format file";
    }
}

done_testing;

__DATA__
# Format,Format Module,Required Module,extensions
markdown,Text::Markup::Markdown,Text::Markdown 1.000004,md,mkdn,mkd,mdown,markdown
