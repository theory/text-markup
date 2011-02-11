package Text::Markup;

use strict;
use 5.8.1;

1;
__END__

=head1 Name

Text::Markup - Parse text markup into HTML

=head1 Synopsis

  my $parser = Text::Markup->new(
      output_dir => '/var/www/html', # . by default
      disallow => [qw(script)],
      strip    => [qw(font)],
  );

  $parser->parse(
      file   => $markup_file,
      format => 'markdown',
  );

=head1 Description



=head2 Interface



=head1 See Also

=over

=item *

The L<markup|https://github.com/github/markup> Ruby provides similar
functionality, and is used to parse F<README.your_favorite_markup> on GitHub.

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
