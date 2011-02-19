package Text::Markup;

use 5.8.1;
use strict;
use Text::Markup::None;
use Carp;

our $VERSION = '0.10';

my %PARSER_FOR;
my %REGEX_FOR = (
    markdown => qr{md|mkdn?|mdown|markdown},
);

sub register {
    my ($class, $name, $regex) = @_;
    my $pkg = caller;
    $REGEX_FOR{$name}  = $regex;
    $PARSER_FOR{$name} = $pkg->can('parser')
        or croak "No parser() function defind in $pkg";
}

sub parser_for {
    my ($self, $format) = @_;
    return Text::Markup::None->can('parser') unless $format;
    return $PARSER_FOR{$format} if $PARSER_FOR{$format};
    my $pkg = __PACKAGE__ . '::' . ucfirst $format;
    eval "require $pkg" or die $@;
    return $PARSER_FOR{$format} = $pkg->can('parser')
        or croak "No parser() function defind in $pkg";
}

sub formats {
    sort keys %REGEX_FOR;
}

sub new {
    my $class = shift;
    bless { @_ } => $class;
}

sub parse {
    my $self = shift;
    my %p = @_;
    my $file = $p{file} or croak "No file parameter passed to parse()";
    croak "$file does not exist" unless -e $file && !-d _;

    my $parser = $self->_get_parser(\%p);
    return $parser->($file, $p{options});
}

sub default_format {
    my $self = shift;
    return $self->{default_format} unless @_;
    $self->{default_format} = shift;
}

sub _get_parser {
    my ($self, $p) = @_;
    my $format = $p->{format}
        || $self->guess_format($p->{file})
        || $self->default_format;

    return $self->parser_for($format);
}

sub guess_format {
    my ($self, $file) = @_;
    for my $format (keys %REGEX_FOR) {
        return $format if $file =~ qr{[.]$REGEX_FOR{$format}$};
    }
    return;
}

1;
__END__

=head1 Name

Text::Markup - Parse text markup into HTML

=head1 Synopsis

  my $parser = Text::Markup->new(default_format => 'markdown');

  my $html = $parser->parse(
      file   => $markup_file,
      format => 'markdown',
  );

=head1 Description

This class is really simple. All it does is take the name of a file and return
an HTML-formatted version of that file. The idea is that one might have files
in lots of different markups, and not know or care what markups each uses.
It's the job of this module to figure that out, parse it, and give you the
resulting HTML.

This distribution includes support for a number of markup formats:

=over

=item * L<HTML|http://whatwg.org/html>

=item * L<Markdown|http://daringfireball.net/projects/markdown/>

=item * L<Pod|perlpod>

=item * L<Textile|http://textism.com/tools/textile/>

=item * L<Trac|http://trac.edgewall.org/wiki/WikiFormatting>

=back

Adding support for more markup languages is straight-forward, and patches
adding them to this distribution are also welcome. See L</Add a Parser> for
step-by-step instructions.

Or if you just want to use this module, then read on!

=head1 Interface

=head2 Constructor

=head3 C<new>

  my $parser = Text::Markup->new(default_format => 'markdown');

Supported parameters:

=over

=item C<default_format>

The default format to use if one isn't passed to C<parse()> and one can't be
guessed.

=back

=head2 Class Methods

=head3 C<register>



=head3 formats



=head2 Instance Methods

=head3 C<parse>

  my $html = $parser->parse(file => $file_to_parse);

Parses a file and return the generated HTML. Supported parameters:

=over

=item C<file>

The file from which to read the markup to be parsed.

=item C<format>

The markup format in the file, which determines the parser used to parse it.
If not specified, Text::Markup will try to guess the format from the file's
suffix. If it can't guess, it falls back on C<default_format>. And if that
attribute is not set, it uses the C<none> parser, which simply encodes the
entire file and wraps it in a C<< <pre> >> element.

=item C<options>

An array reference of options for the parser. See the documentation of the
various parser modules for details.

=back

=head3 C<default_format>

  my $format = $parser->default_format;
  $parser->default_format('markdown');

An accessor method to get and set the default format attribute.

=head3 C<guess_format>

  my $format = $parser->guess_format($filename);

Compares the passed file name's suffix to the regular expressions of all
registered formatting parser and returns the first one that matches. Returns
C<undef> if none matches.

=head1 Add a Parser

Adding support for markup formats not supported by the core Text::Markup
distribution is a straight-forward exercise. Say you wanted to add a "FooBar"
markup parser. Here are the steps to take:

=over

=item 1

Fork L<this project on GitHub|https://github.com/theory/text-markup/>

=item 2

Clone your fork and create a new branch in which to work:

  git clone git@github.com:username/text-markup.git
  cd text-markup
  git checkout -b foorbar

=item 3

Create a new module named C<Text::Markup::FooBar>. The simplest thing to do is
copy an existing module and modify it. The HTML parser is probably the simplest:

  cp lib/Text/Markup/HTML.pm lib/Text/Markup/FooBar.pm
  perl -i -pe 's{HTML}{FooBar}g' lib/Text/Markup/FooBar.pm
  perl -i -pe 's{html}{foobar}g' lib/Text/Markup/FooBar.pm

=item 4

Implement the C<parser> function in your new module. If you were to use the
C<Text::FooBar> parser on CPAN, it might look something like this:

  package Text::Markup::FooBar;

  use 5.8.1;
  use strict;
  use Text::FooBar ();

  sub parser {
      my ($file, $opts) = @_;
      my $md = Text::FooBar->new(@{ $opts || [] });
      open my $fh, '<', $file or die "Cannot open $file: $!\n";
      local $/;
      return $md->parse(<$fh>);
  }

Note that the return value should be properly encoded. Please include an
L<encoding
declaration|http://en.wikipedia.org/wiki/Character_encodings_in_HTML> in the
return value.

=item 5

Edit F<lib/Text/Markup.pm> and add an entry to its C<%REGEX_FOR> hash for your
new format. The key should be the name of the format (lowercase, the same as
the last part of your module's name). The value should be a regular expression
that matches the file extensions that suggest that a file is formatted in your
parser's markup language. For our FooBar parser, the line might look like
this:

    foobar => qr{fb|foob(?:ar)?},

=item 6

Add a file in your parser's markup language to F<t/markups>. It should be
named for your parser and end in F<.txt>, that is, F<t/markups/foobar.txt>.

=item 7

Add an HTML file, F<t/html/foobar.html>, which should be the expected output
once F<t/markups/foobar.txt> is parsed into HTML. This will be used to test
that your parser works correctly.

=item 8

Edit F<t/formats.t> by adding a line to its C<__DATA__> section. The line
should be a comma-separated list describing your parser. The columns are:

=over

=item * Format

The lowercased name of the format.

=item * Format Module

The name of the parser module.

=item * Required Module

The name of a module that's required to be installed in order for your parser
to load.

=item * Extensions

Additional comma-separated values should be a list of file extensions that
your parser should recognize.

=back

So for our FooBar parser, it might look like this:

  markdown,Text::Markup::FooBar,Text::FooBar 0.22,fb,foob,foobar

=item 9

Test your new parser by running

  prove -lv t/formats.t

This will test I<all> included parsers, but of course you should only pay
attention to how your parser works. Tweak until your tests pass.

=item 10

Don't forget to write the documentation in your new parser module! If you
copied F<Text::Markup::HTML>, you can just modify as appropriate.

=item 11

Commit and push the branch to your fork on GitHub:

  git add .
  git commit -am 'Great new FooBar parser!'
  git push -u origin foobar

=item 12

And finally, use the GitHub site to submit a pull request back to the upstream
repository.

=back

If you don't want to submit your parser, you can still create and use one
independently. Rather than add its information to the C<%REGEX_FOR> hash in
this module, you can just load your parser manually, and have it call the
C<register> method, like so:

  use Text::Markup;
  Text::Markup->register(foobar => qr{fb|foob(?:ar)?});

This will be useful for creating private parsers you might not want to
contribute, or that you'd want to distribute independently.

=head1 See Also

=over

=item *

The L<markup|https://github.com/github/markup> Ruby provides similar
functionality, and is used to parse F<README.your_favorite_markup> on GitHub.

=item *

L<Markup::Unified> offers similar functionality.

=back

=head1 Support

This module is stored in an open L<GitHub
repository|http://github.com/theory/text-markup/>. Feel free to fork and
contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/theory/text-markup/issues/> or by sending mail to
L<bug-Text-Markup@rt.cpan.org|mailto:bug-Text-Markup@rt.cpan.org>.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2011 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
