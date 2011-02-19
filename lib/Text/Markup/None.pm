package Text::Markup::None;

use 5.8.1;
use strict;
use HTML::Entities;

our $VERSION = '0.10';

sub parser {
    my ($file, $opts) = @_;
    open my $fh, '<:encoding(UTF-8)', $file or die "Cannot open $file: $!\n";
    local $/;
    my $html = encode_entities(<$fh>);
    utf8::encode($html);
    return qq{<html>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body>
<pre>$html</pre>
</body>
</html>
};
}

1;
