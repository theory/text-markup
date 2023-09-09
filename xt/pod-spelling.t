#!/usr/bin/env perl

use strict;
use Test::More;
eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing POD spelling" if $@;

add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__DATA__
Asciidoc
BBcode
BOM
CommonMark
Daniele
docutils
FooBar
GitHub
Kanashiro
lowercased
Markdown
MediaWiki
MultiMarkdown
reST
reStructuredText
sourcepos
Trac
UI
UTF
Varrazzo
wiki
