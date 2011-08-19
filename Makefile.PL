use inc::Module::Install;
name 'App-pmtemplate';
all_from 'lib/App/pmtemplate.pm';

requires 'Getopt::Compact::WithCmd';
requires 'Text::MicroTemplate';
requires 'Path::Class';
requires 'File::HomeDir';
requires 'Term::ReadLine';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
