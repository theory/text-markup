#!/usr/bin/env perl -w

use strict;
use warnings;
use Test::More 0.96;
use File::Spec::Functions qw(catfile);
use Carp;

# Need to have at least one test outside subtests, in case no subtests are run
# at all. So it might as well be this.
BEGIN { use_ok 'Text::Markup' or die; }

sub slurp($$) {
    my ($filter, $file) = @_;
    $filter ||= sub { shift };
    open my $fh, '<:raw', $file or die "Cannot open $file: $!\n";
    local $/;
    return $filter->(<$fh>);
}

my %filter_for = (
    mediawiki => sub {
        $_[0] =~ s/ö/CGI::escapeHTML(do { use utf8; 'ö' })/e
            if eval { CGI->VERSION >= 4.11 && CGI->VERSION < 4.14 };
        return shift;
    },
    asciidoc => sub {
        # For some reason the file handle decoder doesn't likt the ü output by
        # asciidoc on Windows, and replaces it with hex. Which is weird, but
        # whatever.
        $_[0] =~ s/ü/\\xFC/ if $^O eq 'MSWin32';
        shift;
    },
);

my %parsed_filter_for = (
    rest => sub {
        # docutils space character before closing tag of XML declaration in Nov
        # 2022 (https://github.com/docutils/docutils/commit/f93b895), so remove
        # it when we run tests against older versions.
        $_[0] =~ s/ \?>/\?>/;
    },
);

my @loaded = Text::Markup->formats;
while (my $data = <DATA>) {
    next if $data =~ /^#/;
    chomp $data;
    my ($format, $module, $req, @exts) = split /,/ => $data;
    subtest "Testing $format format" => sub {
        do {
            local $@;
            eval "use $req; 1;";
            if ($@) {
                die $@ if $ENV{TEXT_MARKUP_TEST_ALL}
                    && !$ENV{"TEXT_MARKUP_SKIP_\U$format"};
                plan skip_all => "$module not loading";
            }
        } if $req;

        plan tests => @exts + 5;
        use_ok $module or next;

        push @loaded => $format unless grep { $_ eq $format } @loaded;
        is_deeply [Text::Markup->formats], \@loaded,
            "$format should be loaded";

        my $parser = new_ok 'Text::Markup';
        for my $ext (@exts) {
            is $parser->guess_format("foo.$ext"), $format,
                "Should guess that .$ext extension is $format";
        }

        my $expect = slurp $filter_for{$format}, catfile('t', 'html', "$format.html");
        my $html = $parser->parse(
            file   => catfile('t', 'markups', "$format.txt"),
            format => $format,
        );

        if (my $f = $parsed_filter_for{$format}) {
           $f->($html)
        }

        is $html, $expect, "Parse $format file";

        is $parser->parse(
            file   => catfile('t', 'empty.txt'),
            format => $format,
        ), undef, "Parse empty $format file";
    }
}

done_testing;

__DATA__
# Format,Format Module,Required Module,extensions
markdown,Text::Markup::Markdown,Text::Markdown 1.000004,md,mkdn,mkd,mdown,markdown
html,Text::Markup::HTML,,html,htm,xhtml,xhtm
pod,Text::Markup::Pod,Pod::Simple::XHTML 3.15,pod,pm,pl
trac,Text::Markup::Trac,Text::Trac 0.10,trac,trc
textile,Text::Markup::Textile,Text::Textile 2.10,textile
mediawiki,Text::Markup::Mediawiki,Text::MediawikiFormat 1.0,wiki,mwiki,mediawiki
multimarkdown,Text::Markup::Multimarkdown,Text::MultiMarkdown 1.000033,mmd,mmkdn,mmkd,mmdown,mmarkdown
rest,Text::Markup::Rest,Text::Markup::Rest,rest,rst
asciidoc,Text::Markup::Asciidoc,Text::Markup::Asciidoc,asciidoc,asc,adoc
bbcode,Text::Markup::Bbcode,Parse::BBCode,bbcode,bb
creole,Text::Markup::Creole,Text::WikiCreole,creole
