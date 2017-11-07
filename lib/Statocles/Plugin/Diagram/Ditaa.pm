package Statocles::Plugin::Diagram::Ditaa;

use Mojo::File ();
use Statocles::Base 'Class';
use Statocles::Image;
with 'Statocles::Plugin';

BEGIN {
  eval { require Alien::Ditaa; 1 }
    or die sprintf "Error loading %s. To use this plugin, install %s\n", __PACKAGE__, 'Alien::Ditaa';
  eval { require MIME::Base64; 1 }
      or die sprintf "Error loading %s. To use this plugin, install %s\n", __PACKAGE__, 'MIME::Base64';
};

has converter => (
  is => 'ro',
  isa => InstanceOf['Alien::Ditaa'],
  default => sub { Alien::Ditaa->new() },
);

sub ditaa {
  my ($self, $arg, @args) = @_;
  my $text = pop @args;
  $text = $text->() if ref $text eq 'CODE';
  my $tmp = Mojo::File::tempdir('ditaa.XXXXX');
  my $input  = $tmp->child('diagram.txt')->spurt($text);
  my $output = $tmp->child('diagram.png');
  if (0 == $self->converter->run_ditaa($input, $output)) {
    my $base64 = MIME::Base64::encode_base64($output->slurp, '');
    my $img = Statocles::Image->new(
        src     => "data:image/png;base64,$base64",
        alt     => 'diagram',
    );
    return qq{<img src="data:image/png;base64,$base64" />};
  } else {
    warn $self->converter->last_run_output;
  }
}

sub register {
  my ($self, $site) = @_;
  $site->theme->helper( diagram => sub { $self->ditaa( @_ ) } );
}

1;
