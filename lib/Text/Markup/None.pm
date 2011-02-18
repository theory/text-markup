package Text::Markup::None;

use 5.8.1;
use strict;
use HTML::Entities;

our $VERSION = '0.10';

sub parser {
    my ($file, $opts) = @_;
    open my $fh, '<:utf8', $file or die "Cannot open $file: $!\n";
    local $/;
    return '<pre>' . encode_entities(<$fh>) . '</pre>';
}

1;
