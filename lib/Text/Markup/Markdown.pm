package Text::Markup::Markdown;

use 5.8.1;
use strict;
use Text::Markdown ();

our $VERSION = '0.10';

sub parser {
    my ($file, $opts) = @_;
    my $md = Text::Markdown->new(@{ $opts || [] });
    open my $fh, '<:encoding(UTF-8)', $file or die "Cannot open $file: $!\n";
    local $/;
    my $html = $md->markdown(<$fh>);
    utf8::encode($html);
    return qq{<html>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body>
$html
</body>
</html>
};

}

1;
