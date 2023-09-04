package Text::Markup::Asciidoc;

use 5.8.1;
use strict;
use warnings;
use File::Spec;
use constant WIN32  => $^O eq 'MSWin32';
use Symbol 'gensym';
use IPC::Open3;
use utf8;

our $VERSION = '0.30';

# Find Asciidoc.
sub _find_cli {
    my @names = (
        (map {
            (WIN32 ? ("$_.exe", "$_.bat") : ($_))
        } qw(asciidoctor asciidoc)),
        'asciidoc.py',
    );
    my $cli;
    EXE: {
        for my $exe (@names) {
            for my $p (File::Spec->path) {
                my $path = File::Spec->catfile($p, $exe);
                next unless -f $path && -x $path;
                $cli = $path;
                last EXE;
            }
        }
    }

    unless ($cli) {
        use Carp;
        my $sep = WIN32 ? ';' : ':';
        my $list = join(', ', @names[0..$#names-1]) . ", or $names[-1]";
        Carp::croak(
            "Cannot find $list in path " . join $sep => File::Spec->path
        );
    }

    # Make sure it looks like it will work.
    my $output = gensym;
    my $pid = open3 undef, $output, $output, $cli, '--version';
    waitpid $pid, 0;
    if ($?) {
        use Carp;
        local $/;
        Carp::croak( qq{$cli will not execute\n}, <$output> );
    }
    return $cli;
}

my $ASCIIDOC = _find_cli;

# Arguments to pass to asciidoc.
# Restore --safe if Asciidoc ever fixes it with the XHTML back end.
# https://groups.google.com/forum/#!topic/asciidoc/yEr5PqHm4-o
my @OPTIONS = qw(
    --no-header-footer
    --out-file -
    --attribute newline=\\n
);

sub parser {
    my ($file, $encoding, $opts) = @_;
    my $html = do {
        my $fh = _fh(
            $ASCIIDOC, @OPTIONS,
            '--attribute' => "encoding=$encoding",
            $file
        );

        binmode $fh, ":encoding($encoding)";
        local $/;
        <$fh>;
    };

    # Make sure we have something.
    return unless $html =~ /\S/;
    utf8::encode $html;
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

# Stolen from SVN::Notify.
sub _fh {
    if (WIN32) {
        my $cmd = q{"} . join(q{" "}, @_) . q{"|};
        open my $fh, $cmd or die "Cannot fork: $!\n";
        return $fh;
    }

    my $pid = open my $fh, '-|';
    die "Cannot fork: $!\n" unless defined $pid;

    if ($pid) {
        # Parent process, return the file handle.
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

Text::Markup::Asciidoc - Asciidoc parser for Text::Markup

=head1 Synopsis

  use Text::Markup;
  my $html = Text::Markup->new->parse(file => 'hello.adoc');
  my $raw_asciidoc = Text::Markup->new->parse(file => 'hello.adoc', raw => 1 );

=head1 Description

This is the L<Asciidoc|https://asciidoc.org/> parser for L<Text::Markup>. It
depends on the C<asciidoctor> command-line application; see the
L<installation docs|https://asciidoctor.org/#installation> for details, or
use the command C<gem install asciidoctor>. It falls back on the
L<legacy C<asciidoc>|https://asciidoc-py.github.io> processor if
C<asciidoctor> is not available.

Text::Markup::Asciidoc recognizes files with the following extensions as
Asciidoc:

=over

=item F<.asciidoc>

=item F<.asc>

=item F<.adoc>

=back

Normally this parser returns the output of C<asciidoc> wrapped in a minimal
HTML page skeleton. If you would prefer to just get the exact output returned
by C<asciidoc>, you can pass in a true value for the C<raw> option.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2012-2019 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
