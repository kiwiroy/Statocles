
use Test::Lib;
use My::Test;
use Mojo::Loader qw{data_section};

BEGIN {
    eval { require Alien::Ditaa; 1 } or plan skip_all => 'Alien::Ditaa needed';
};

use Statocles::Plugin::Diagram::Ditaa;

my $SHARE_DIR = path( __DIR__, '..', 'share' );

subtest 'ditaa basics' => sub {
  my $plugin = new_ok('Statocles::Plugin::Diagram::Ditaa', []);

  my $site = build_test_site();
  my $page = Statocles::Page::Plain->new(
      path => 'test.html',
      site => $site,
      content => '',
  );
  $plugin->register( $site );

  my $diagram = data_section __PACKAGE__, 'diagram.txt';
  chomp $diagram;
  my $output = $plugin->ditaa({page => $page}, $diagram);
  my $base64 = data_section __PACKAGE__, 'test.png.base64';
  chomp $base64;
  ok $output, 'something';
  is $output, qq{<img src="data:image/png;base64,$base64" />}, 'image generated';

};


done_testing;

__DATA__
@@ test.png.base64
iVBORw0KGgoAAAANSUhEUgAAAIwAAAB+CAIAAAB5+G57AAADkElEQVR42u3dO0sjUQCG4cgW4nrpRASx8A+ooIVip2hvI1tYWAhWKgi6jQrCWlgoWIhoIYiQxhsWIWAjmsYUEkglAXEwMhYmjIwGA8PufnhY94bNbowH875VcjKO4zxzJhMxMfSNrC/ELgCJCor0lSwLJJAIJJAIJAIJJAKJQAKJQAIJJJAIJJAIJAIJJAKJQAKJQAKJQCKQQCKQCCSQCCSQQColpBD9nqVIvCvv554NhTzP830/l8vl8/kgCECyEclxHNd1M5mMqOQEko1IyWQylUql02k5aT6BZCNSLBZLJBJy0nzSZALJRqRIJCInzSed9/T8BJKNSOFwOBqNxuNxTSad8UACCSSQQAIJJJBAAgkkkEACCSSQQAIJJJBAAgkkkEB6FaTV1dUvL6SHQLICqaWl5eNTFRUV5k+ldMOMNDc3/8MKs9msdtz5+TlIhe/m5sYgua77P+sZGRnRSmZmZkAqHpK+9dLSUltbW319fXd399nZmRm/u7ubn5/v6empq6vTdFxeXtbg1taW7molDQ0NHR0dFxcXIBUDaWxsTINdXV3T09M1NTXV1dWe52l8aGhI4319fSsrK6Ojo4LU4NHRkcA03tnZOTk5qXWC9OpIjuN8eOr29lZ3h4eHtcDa2ppui0G3FxYWON29MdLBwYFGNHs+PWVmiaaIHlpfXzfLt7a2bmxsBEEA0tsg7e7umuu9qampzz/a3t42jx4fH7e3t5uv6u/vB+ltkPTzm8GTk5OXvnBnZ0cLlJWVXV1dPT+HjY+Pg1S8C4fBwUENNjU1zc3N7e3tzc7Omgs5PT8tLi6enp5ubm5qAb2u8n1f49pxutvY2KhZyIVDkZAeHh4mJiaeX+rW1taaU5kuvisrKzVSXl7e29t7eHholteT08DAQFVVlR7a398HqXhpAy4vL7PZ7B+DOsXd39//vfzj4+P19TWnO37BChJIIIEEEkgggQQSSCCBhA1IIIEEEkgggQQSSCCBBBJIIIEEEkgggQQSSO8XiX7NRiTleZ7jOMlkMhaLRSKRcGln42ewKt/3XdfVgZNIJLR90dLOxk8zVrlcTvM6nU5ry3QExUs7Gz8XXOXzeR0y2iYdO5rjqdLOxk/YV0EQaGt01GizdBbOlHY2/q8KKmwggUQggUQgEUggEUgEEkgEEkgggUQggUQgEUggEUgEEkgEEkgEEoH03pHI3vejsQtAogL0He3B8BNG7ukJAAAAAElFTkSuQmCC
@@ diagram.txt
+--------+
|        |
|  Test  |
|        |
+---+----+
@@ complex.txt
