package App::pmtemplate;
use strict;
use warnings;
use Getopt::Compact::WithCmd;
use Text::MicroTemplate;
use Path::Class;
use File::HomeDir;
use Term::ReadLine;

our $VERSION = '0.01';

my ( $base_dir, $template_dir, $config_file );

sub run {
    my $class = shift;

    my $go = Getopt::Compact::WithCmd->new(
        name           => 'pmtemplate',
        version        => '0.01',
        command_struct => {
            init   => { desc => 'initialize configuration', },
            create => {
                options => {
                    'dir' => {
                        alias => 'd',
                        desc  => 'target directory',
                        type  => '=s',
                        opts  => { default => '.', },
                    },
                    'template' => {
                        alias => 't',
                        desc  => 'module template',
                        type  => '=s',
                        opts  => { default => 'default.mt' },
                    },
                },
                desc => 'create .pm file',
                args => 'package_name',
            },
        },
    );

    my $opts    = $go->opts    || +{};
    my $command = $go->command || q{};

    $base_dir     = dir( File::HomeDir->my_home, '.pmtemplate' );
    $template_dir = $base_dir->subdir('template');
    $config_file  = $base_dir->file('config.pl');

    if ( $command eq 'init' ) {
        $class->init($opts);
    }
    elsif ( $command eq 'create' ) {
        $class->create($opts);
    }
    else {
        $go->show_usage();
    }
}

sub init {
    my ( $class, $opts ) = @_;

    if ( !-e $base_dir ) {
        $base_dir->mkpath;
    }

    if ( !-e $template_dir ) {
        $template_dir->mkpath;
    }

    my $term  = Term::ReadLine->new('pmtemplate configuration');
    my $name  = $term->readline("Enter your name: ");
    my $email = $term->readline("Enter your E-mail address: ");

    my $config_fh = $config_file->openw;
    print $config_fh <<"__CONFIG__";
+{
	name => "$name",
	email => "$email",
};
__CONFIG__
    close $config_fh;

    my $default_template = $template_dir->file('default.mt');
    my $dt_fh            = $default_template->openw;
    print $dt_fh <<'__TEMPLATE__';
package <?= $_[0]->{package_name} ?>;
use strict;
use warnings;

1;
__END__

=head1 NAME

<?= $_[0]->{package_name} ?> - 

=head1 SYNOPSIS

    use <?= $_[0]->{package_name} ?>;

=head1 DESCRIPTION

<?= $_[0]->{package_name} ?> is 

=head1 AUTHOR

<?= $_[0]->{name} ?><lt><?= $_[0]->{email} ?></gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__TEMPLATE__
    close $dt_fh;

    print "Initialization succeed!\n";

}

sub create {
    my ( $class, $opts ) = @_;
    my $package_name = shift @ARGV;

    if ( !-f $config_file ) {
        print
            "Configuration file not found. Please execute 'pmtemplate init'\n";
        exit 1;
    }

    my $config = do $config_file;

    my $template_fh = $template_dir->file( $opts->{template} )->openr;
    my $template = do { local $/; <$template_fh> };

    my $mt = Text::MicroTemplate->new(
        template    => $template,
        escape_func => undef,
    );

    my $code   = $mt->code;
    my $render = eval $code or die $@;
    my $result     = $render->(
        {   name         => $config->{name},
            email        => $config->{email},
            package_name => $package_name,
        }
    );

	my $target_dir = dir($opts->{dir});
	$target_dir->mkpath;
	my $pmfile = (split '::', $package_name )[-1] . '.pm';
	my $pmfile_fh = $target_dir->file($pmfile)->openw;
	print $pmfile_fh $result;
	close $pmfile_fh;

}

1;
__END__

=head1 NAME

App::pmtemplate -

=head1 SYNOPSIS

  use App::pmtemplate;

=head1 DESCRIPTION

App::pmtemplate is

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
