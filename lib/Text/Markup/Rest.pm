package Text::Markup::Rest;

use 5.8.1;
use strict;

our $VERSION = '0.15';

# Optional arguments to pass to rst2html
our @OPTIONS = ('--no-raw', '--no-file-insertion',
                '--stylesheet=', '--cloak-email-address');

sub parser {
    my ($file, $encoding, $opts) = @_;
    open my $fh, "-|", "rst2html @OPTIONS $file",
        or die "Cannot execute rst2html $file: $!\n";
    local $/;
    return <$fh>;
}

1;
__END__

=head1 Name

Text::Markup::Rest - reStructuredText parser for Text::Markup

=head1 Synopsis

  use Text::Markup;
  my $html = Text::Markup->new->parse(file => 'hello.rst');

=head1 Description

This is the L<reStructuredText|http://docutils.sourceforge.net/docs/user/rst/quickref.html>
parser for L<Text::Markup>.  It uses the reference docutils implementation of
the parser invoking 'rst2html' to do the job, so it depends on the 'docutils'
Python package (which can be found as 'python-docutils' in many Linux
distribution, or installed using the command 'easy_install docutils').  It
recognizes files with the following extensions as reST:

=over

=item F<.rest>

=item F<.rst>

=back

=head1 Author

Daniele Varrazzo <daniele.varrazzo@gmail.com>

=head1 Copyright and License

Copyright (c) 2011 Daniele Varrazzo. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
