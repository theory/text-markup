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

    my $parser = $self->get_parser(\%p);
    return $parser->($file, $p{options});
}

sub default_format {
    my $self = shift;
    return $self->{default_format} unless @_;
    $self->{default_format} = shift;
}

sub get_parser {
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
