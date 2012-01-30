package Text::Markup::Rest;

use 5.8.1;
use strict;
use File::Spec;
use File::Basename ();
use constant WIN32  => $^O eq 'MSWin32';

our $VERSION = '0.16';

# Find rst2html (process stolen from App::Info).
my $rst2html;
foreach my $p (File::Spec->path) {
    foreach my $f (qw(rst2html rst2html.py)) {
        my $path = File::Spec->catfile($p, $f);
        if (-f $path && -x $path) {
            $rst2html = $path;
            last;
        }
    }
}

if ($rst2html) {
    # We have it, but use our custom version instead.
    $rst2html = File::Spec->catfile(
        File::Basename::dirname(__FILE__),
        'rst2html_lenient.py'
    );
} else {
    use Carp;
    Carp::croak(
        'Cannot find rst2html.py in path ' . join ':', File::Spec->path
    );
}

# Optional arguments to pass to rst2html
my @OPTIONS = qw(
    --no-raw
    --no-file-insertion
    --stylesheet=
    --cloak-email-address
    --no-generator
    --quiet
);

sub parser {
    my ($file, $encoding, $opts) = @_;
    my $html = do {
        my $fh = _fh($encoding, $rst2html, @OPTIONS, $file);
        local $/;
        <$fh>;
    };

    # Make sure we have something.
    return undef if $html =~ m{<div\s+class\s*=\s*(['"])document\1>\s+</div>}ms;

    # Seems that --no-generator is not respected. :-(
    $html =~ s{^\s*<meta\s+name\s*=\s*(['"])generator\1[^>]+>\n}{}ms;

    return $html;
}

# Stolen from SVN::Notify.
sub _fh {
    my $encoding = shift;
    if (WIN32) {
        my $cmd = join join(q{" "}, @_) . q{"|};
        open my $fh, $cmd or die "Cannot fork: $!\n";
        binmode $fh, ":encoding($encoding)" if $encoding;
        return $fh;
    }

    my $pid = open my $fh, '-|';
    die "Cannot fork: $!\n" unless defined $pid;

    if ($pid) {
        # Parent process. Set the encoding layer and return the file handle.
        binmode $fh, ":encoding($encoding)" if $encoding;
        return $fh;
    } else {
        # Child process. Execute the commands.
        exec @_ or die "Cannot exec $_[0]: $!\n";
        # Not reached.
    }
}

1;
__END__

=head1 Name

Text::Markup::Rest - reStructuredText parser for Text::Markup

=head1 Synopsis

  use Text::Markup;
  my $html = Text::Markup->new->parse(file => 'hello.rst');

=head1 Description

This is the
L<reStructuredText|http://docutils.sourceforge.net/docs/user/rst/quickref.html>
parser for L<Text::Markup>. It depends on the C<docutils> Python package
(which can be found as C<python-docutils> in many Linux distributions, or
installed using the command C<easy_install docutils>). It recognizes files
with the following extensions as reST:

=over

=item F<.rest>

=item F<.rst>

=back

=head1 Author

Daniele Varrazzo <daniele.varrazzo@gmail.com>

=head1 Copyright and License

Copyright (c) 2011-2012 Daniele Varrazzo. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
