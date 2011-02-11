use strict;
use warnings;
use Module::Build;

Module::Build->new(
    module_name        => 'Text-Markup',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => '0.30', },
    build_requires     => {
        'Module::Build' => '0.30',
        'Test::More'    => '0.70',
    },
    requires => {
        'perl'           => 5.008001,
    },
    recommends => {
        'Text::Markdown'      => '1.000004',
        'Test::Pod'           => '1.41',
        'Test::Pod::Coverage' => '1.06',
    },
    meta_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/Text-Markup/',
            bugtracker => 'http://github.com/theory/text-markup/issues/',
            repository => 'http://github.com/theory/text-markup/tree/',
        }
    },
)->create_build_script;
