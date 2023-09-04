package Text::Markup::Multimarkdown;

use 5.8.1;
use strict;
use warnings;
use File::BOM qw(open_bom);
use Text::MultiMarkdown ();

our $VERSION = '0.30';

sub parser {
    my ($file, $encoding, $opts) = @_;
    my $md = Text::MultiMarkdown->new(@{ $opts || [] });
    open_bom my $fh, $file, ":encoding($encoding)";
    local $/;
    my $html = $md->markdown(<$fh>);
    return unless $html =~ /\S/;
    utf8::encode($html);
    return $html if $opts->{raw};
    return qq{<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body>
$html
</body>
</html>
};

}

1;
__END__

=head1 Name

Text::Markup::Multimarkdown - MultiMarkdown parser for Text::Markup

=head1 Synopsis

  my $html = Text::Markup->new->parse(file => 'README.md');
  my $raw  = Text::Markup->new->parse(file => 'README.md', raw => 1);

=head1 Description

This is the L<MultiMarkdown|https://fletcherpenney.net/multimarkdown/> parser
for L<Text::Markup>. It reads in the file (relying on a
L<BOM|https://www.unicode.org/unicode/faq/utf_bom.html#BOM>), hands it off to
L<Text::MultiMarkdown> for parsing, and then returns the generated HTML as an
encoded UTF-8 string with an C<http-equiv="Content-Type"> element identifying
the encoding as UTF-8.

It recognizes files with the following extensions as MultiMarkdown:

=over

=item F<.mmd>

=item F<.mmkd>

=item F<.mmkdn>

=item F<.mmdown>

=item F<.multimarkdown>

=back

Normally this module returns the output wrapped in a minimal HTML document
skeleton. If you would like the raw output without the skeleton, you can pass
the C<raw> option to C<parse>.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2011-2023 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
