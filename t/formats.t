#!/usr/bin/env perl -w

use strict;
use warnings;
use Test::More 0.96;
use Text::Markup;
use File::Spec::Functions qw(catfile);

sub slurp($) {
    my $file = shift;
    open my $fh, '<:raw', $file or die "Cannot open $file: $!\n";
    local $/;
    return <$fh>;
}

my @loaded = Text::Markup->formats;
while (my $data = <DATA>) {
    next if $data =~ /^#/;
    chomp $data;
    my ($format, $module, $req, @exts) = split /,/ => $data;
    subtest "Testing $format format" => sub {
        local $@;
        eval "use $req; 1;" if $req;
        plan skip_all => "$module not installed" if $@;
        plan tests => @exts + 4;
        use_ok $module or next;

        push @loaded => $format unless grep { $_ eq $format } @loaded;
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
        ), slurp catfile('t', 'html', "$format.html"), "Parse $format file";
    }
}

done_testing;

__DATA__
# Format,Format Module,Required Module,extensions
markdown,Text::Markup::Markdown,Text::Markdown 1.000004,md,mkdn,mkd,mdown,markdown
html,Text::Markup::HTML,,html,htm,xhtml,xhtm
pod,Text::Markup::Pod,Pod::Simple::XHTML 3.15,pod,pm,pl
trac,Text::Markup::Trac,Text::Trac 0.10,trac,trc
