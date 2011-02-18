#!/usr/bin/env perl -w

use strict;
use warnings;
use File::Spec::Functions qw(catfile tmpdir);
#use Test::More tests => 1;
use Test::More 'no_plan';
use Test::File;
use Test::File::Contents;
use Test::Output;
use HTML::Entities;
use Encode;

BEGIN { use_ok 'Text::Markup' or die; }

can_ok 'Text::Markup' => qw(
    register
    formats
    new
    parse
    default_format
    get_parser
    output_handle_for
);

is_deeply [Text::Markup->formats], [],
    'Should be no registered parsers';

# Register one.
PARSER: {
    package My::Cool::Parser;
    use Text::Markup;
    Text::Markup->register(cool => qr{cool});
    sub parser {
        return $_[1] ? $_[1]->[0] : 'hello';
    }
}

is_deeply [Text::Markup->formats], ['cool'],
    'Should be now have the "cool" parser';

my $parser = new_ok 'Text::Markup';
is $parser->default_format, undef, 'Should have no default format';

$parser = new_ok 'Text::Markup', [default_format => 'cool'];
is $parser->default_format, 'cool', 'Should have default format';

is $parser->get_parser({ format => 'cool' }), My::Cool::Parser->can('parser'),
    'Should be able to find specific parser';

is $parser->get_parser({ from => 'foo' }), My::Cool::Parser->can('parser'),
    'Should be able to find default format parser';

is $parser->get_parser({format => 'default'}), Text::Markup::None->can('parser'),
    'Should be able to find the default parser';

ok $parser->default_format('none'), 'Set the default format to "none"';
is $parser->get_parser({ from => 'foo'}), Text::Markup::None->can('parser'),
    'Should be find the specified default parser';

# Now make it guess the format.
$parser->default_format(undef);
is $parser->get_parser({ from => 'foo.cool'}), My::Cool::Parser->can('parser'),
    'Should be able to guess the parser from the file name';

# Now test guess_format.
is $parser->guess_format('foo.cool'), 'cool',
    'Should guess "cool" format from "foo.cool"';
is $parser->guess_format('foocool'), undef,
    'Should not guess "cool" format from "foocool"';
is $parser->guess_format('foo.cool.txt'), undef,
    'Should not guess "cool" format from "foo.cool.txt"';

# Add another parser.
PARSER: {
    package My::Funky::Parser;
    Text::Markup->register(funky => qr{funky(?:[.]txt)?});
    sub parser {
        use utf8;
        return 'fünky';
    }
}

is_deeply [Text::Markup->formats], ['cool', 'funky'],
    'Should be now have the "cool" and "funky" parsers';
is $parser->guess_format('foo.cool'), 'cool',
    'Should still guess "cool" format from "foo.cool"';
is $parser->guess_format('foo.funky'), 'funky',
    'Should guess "funky" format from "foo.funky"';
is $parser->guess_format('foo.funky.txt'), 'funky',
    'Should guess "funky" format from "foo.funky.txt"';

# Test the output file handle method.
is $parser->output_handle_for, *STDOUT,
    'Default output handle should be STDOUT';

# Test it with an actual file.
my $outfile = catfile tmpdir, "text-xpath-t-base.t$$";
END { unlink $outfile }

file_not_exists_ok $outfile, 'Test file should not exist';
ok my $fh = $parser->output_handle_for($outfile),
    'Get file handle for output file';
print $fh "hi there, $$";
close $fh;
file_exists_ok $outfile, 'Now we should have the output file';
file_contents_is $outfile, "hi there, $$", 'And we should have written to it';

# Now try parsing.
stdout_is { $parser->parse(
    from   => 'README',
    format => 'cool',
) } 'hello', 'Test the "cool" parser';

# Send output to a file.
ok $parser->parse(
    from   => 'README',
    to     => $outfile,
    format => 'funky',
), 'Test the "funky" parser';

# Data from Test::File::Contents is not decoded.
file_contents_is $outfile, 'fünky',
    'The parser output should have been written to the file.';

# Test opts to the parser.
stdout_is { $parser->parse(
    from    => 'README',
    format  => 'cool',
    options => ['goodbye'],
) } 'goodbye', 'Test the "cool" parser with options';

# Test the "none" parser.
my $output = do {
    open my $fh, '<:utf8', __FILE__ or die 'Cannot open ' . __FILE__ . ": $!\n";
    local $/;
    '<pre>' . encode_entities(<$fh>) . '</pre>';
};
$parser->default_format(undef);
ok $parser->parse(
    from => __FILE__,
    to   => $outfile,
), 'Test the "none" parser';
file_contents_is $outfile, encode_utf8($output),
    'Its output should look as expected';
