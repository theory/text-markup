use strict;
use warnings;
use Module::Build;

Module::Build->new(
    module_name        => 'Text::Markup',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => '0.30', },
    build_requires     => {
        'File::Path'            => 0,
        'File::Spec::Functions' => 0,
        'Module::Build'         => '0.30',
        'Test::File'            => '1.08',
        'Test::More'            => '0.96',
        'Test::Output'          => '0.11',
    },
    requires => {
        'perl'           => 5.008001,
        'HTML::Entities' => 0,
        'File::BOM'      => '0.14',
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
