package My::Test;

# ABSTRACT: Utilities for testing Statocles Tests

use strict;
use warnings;

use base 'Import::Base';
use Mojo::Util qw{monkey_patch};
use Mojo::Exception;

monkey_patch 'Mojo::File',
  parent => sub { shift->dirname; },
  mkpath => sub { shift->make_path },
  is_dir => sub { -d "$_[0]" },
  is_file => sub { -f "$_[0]" },
  is_absolute => sub { shift->is_abs },
  exists => sub { -e "$_[0]" },
  touchpath => sub { shift->make_path },
  spew_utf8 => sub { shift->spurt(@_) },
  spew => sub { shift->spurt(@_) },
  slurp_utf8 => sub {
    my $self = shift;
    my $res = eval { $self->slurp };
    if ($@) {
      my $e = Mojo::Exception->new($@)->inspect;
      $e->{op} = 'open';
      die $e;
    }
    return $res;
  },
  absolute => sub { shift->to_abs() },
  is_rootdir => sub { shift->splitdir },
  relative => sub { shift->to_rel(@_) },
  stringify => sub { shift->to_string; },
  cwd => sub { Mojo::File->new('.')->to_abs },
  iterator => sub {
    my @all = @{shift->list_tree(@_)};
    sub {
      return shift @all;
    }
  };

our @IMPORT_MODULES = (
    sub {
        # Disable spurious warnings on platforms that Net::DNS::Native does not
        # support. We don't use this much mojo
        $ENV{MOJO_NO_NDN} = 1;
        return;
    },
    strict => [],
    warnings => [],
    feature => [qw( :5.10 )],
#    'Path::Tiny' => [qw( rootdir cwd )],
    'DateTime::Moonpig',
    'Statocles',
    qw( Test::More Test::Deep Test::Differences Test::Exception ),
    'Dir::Self' => [qw( __DIR__ )],
#    'Path::Tiny' => [qw( path tempdir cwd )],
    'Mojo::File' => [qw{path tempdir}],
    'Cwd' => ['cwd'],
    'Statocles::Test' => [qw(
      build_test_site build_test_site_apps
      build_temp_site
    )],
    'Statocles::Types' => [qw( DateTimeObj )],
    'My::Test::_Extras' => [qw( test_constructor test_pages )],
);

package My::Test::_Extras;

$INC{'My/Test/_Extras.pm'} = 1;

require Exporter;
*import = \&Exporter::import;

our @EXPORT_OK = qw( test_constructor test_pages );

sub test_constructor {
    my ( $class, %args ) = @_;

    my %required = $args{required} ? ( %{ $args{required} } ) : ();
    my %defaults = $args{default}  ? ( %{ $args{default} } )  : ();
    require Test::Builder;
    require Scalar::Util;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $tb = Test::Builder->new();

    $tb->subtest(
        $class . ' constructor' => sub {
            my $got    = $class->new(%required);
            my $want   = $class;
            my $typeof = do {
                    !defined $got                ? 'undefined'
                  : !ref $got                    ? 'scalar'
                  : !Scalar::Util::blessed($got) ? ref $got
                  : eval { $got->isa($want) } ? $want
                  :                             Scalar::Util::blessed($got);
            };
            $tb->is_eq( $typeof, $class,
                'constructor works with all required args' );

            if ( $args{required} ) {
                $tb->subtest(
                    'required attributes' => sub {
                        for my $key ( keys %required ) {
                            require Test::Exception;
                            &Test::Exception::dies_ok(
                                sub {
                                    $class->new(
                                        map { ; $_ => $required{$_} }
                                        grep { $_ ne $key } keys %required,
                                    );
                                },
                                $key . ' is required'
                            );
                        }
                    }
                );
            }

            if ( $args{default} ) {
                $tb->subtest(
                    'attribute defaults' => sub {
                        my $obj = $class->new(%required);
                        for my $key ( keys %defaults ) {
                            if ( ref $defaults{$key} eq 'CODE' ) {
                                local $_ = $obj->$key;
                                $tb->subtest(
                                    "$key default value" => $defaults{$key} );
                            }
                            else {
                                require Test::Deep;
                                Test::Deep::cmp_deeply( $obj->$key,
                                    $defaults{$key}, "$key default value" );
                            }
                        }
                    }
                );
            }

        }
    );
}

sub test_pages {
    my ( $site, $app ) = ( shift, shift );

    require Test::Builder;
    require Scalar::Util;

    my %opt;
    if ( ref $_[0] eq 'HASH' ) {
        %opt = %{ +shift };
    }

    my %page_tests = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $tb = Test::Builder->new();

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my @pages = $app->pages;

    $tb->is_eq(
        scalar @pages,
        scalar keys %page_tests,
        'correct number of pages'
    ) or $tb->diag( "Got: " . join( ", ", map { $_->path } @pages ) . "\n" . "Expect: " . join( ", ", keys %page_tests ) );

    for my $page (@pages) {
        $tb->ok( $page->DOES('Statocles::Page'), 'must be a Statocles::Page' );

        my $date   = $page->date;
        my $want   = 'DateTime::Moonpig';
        my $typeof = do {
                !defined $date                ? 'undefined'
              : !ref $date                    ? 'scalar'
              : !Scalar::Util::blessed($date) ? ref $date
              : eval { $date->isa($want) } ? $want
              :                              Scalar::Util::blessed($date);
        };
        $tb->is_eq( $typeof, $want, 'must set a date' );

        if ( !$page_tests{ $page->path } ) {
            $tb->ok( 0, "No tests found for page: " . $page->path );
            next;
        }

        my $output;

        if ( $page->has_dom ) {
            $output = "".$page->dom;
        }
        else {
            $output = $page->render;
            # Handle filehandles from render
            if ( ref $output eq 'GLOB' ) {
                $output = do { local $/; <$output> };
            }
            # Handle Path::Tiny from render
            elsif ( Scalar::Util::blessed( $output ) && $output->isa( 'Path::Tiny' ) ) {
                $output = $output->slurp_raw;
            }
        }

        if ( $page->path =~ /[.](?:html|rss|atom)$/ ) {
            require Mojo::DOM;
            my $dom = Mojo::DOM->new($output);
            $tb->ok( 0, "Could not parse dom" ) unless $dom;
            $tb->subtest(
                'html content: ' . $page->path,
                $page_tests{ $page->path },
                $output, $dom
            );
        }
        elsif ( $page_tests{ $page->path } ) {
            $tb->subtest( 'text content: ' . $page->path,
                $page_tests{ $page->path }, $output );
        }
        else {
            $tb->ok( 0, "Unknown page: " . $page->path );
        }

    }

    $tb->ok( !@warnings, "no warnings!" ) or $tb->diag( join "\n", @warnings );
}

1;
