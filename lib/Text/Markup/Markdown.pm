package Text::Markup::Markdown;

use 5.8.1;
use strict;
use Text::Markup;
use Text::Markdown ();

our $VERSION = '0.10';

sub parser {
    my ($file, $opts) = @_;
    my $md = Text::Markdown->new(@{ $opts || [] });
    open my $fh, '<:encoding(UTF-8)', $file or die "Cannot open $file: $!\n";
    local $/;
    return $md->markdown(<$fh>);
}

1;
