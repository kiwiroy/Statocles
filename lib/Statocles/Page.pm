package Statocles::Page;
# ABSTRACT: Render documents into HTML

use Statocles::Role;
use Statocles::Template;
use Text::Markdown;

requires 'vars';

=attr app

The application this page came from, so we can give it to the templates.

=cut

has app => (
    is => 'ro',
    isa => InstanceOf['Statocles::App'],
);

=attr path

The absolute URL path to save this page to.

=cut

has path => (
    is => 'rw',
    isa => Path,
    coerce => Path->coercion,
    required => 1,
);

=attr published

The publish date/time of this page. A L<Time::Piece> object.

=cut

has published => (
    is => 'ro',
    isa => InstanceOf['Time::Piece'],
);

=attr links

A hash of arrays of links to pages related to this page. Possible keys:

    feed        - Feed pages related to this page

Each item in the array is a hash with the following keys:

    href        - The page for the link
    type        - The MIME type of the link, optional

=cut

has links => (
    is => 'ro',
    isa => HashRef[ArrayRef[HashRef]],
    default => sub { {} },
);

=attr markdown

The L<Text::Markdown> object to render document Markdown.

=cut

has markdown => (
    is => 'ro',
    isa => InstanceOf['Text::Markdown'],
    default => sub { Text::Markdown->new },
);

=attr template

The main L<template|Statocles::Template> for this page. The result will be
wrapped in the L<layout template|/layout>.

=cut

my @template_attrs = (
    is => 'ro',
    isa => InstanceOf['Statocles::Template'],
    coerce => Statocles::Template->coercion,
    default => sub {
        Statocles::Template->new( content => '<%= $content %>' ),
    },
);

has template => @template_attrs;

=attr layout

The layout L<template|Statocles::Template> for this page, which will wrap the content generated by the
L<template|/template>.

=cut

has layout => @template_attrs;

=attr search_change_frequency

How frequently a search engine should check this page for changes. This is used
in the L<sitemap.xml|http://www.sitemaps.org> to give hints to search engines.

Should be one of:

    always
    hourly
    daily
    weekly
    monthly
    yearly
    never

Defaults to C<weekly>.

B<NOTE:> This is only a hint to search engines, not a command. Pages marked C<hourly>
may be checked less often, and pages marked C<never> may still be checked once in a
while. C<never> is mainly used for archived pages or permanent links.

=cut

has search_change_frequency => (
    is => 'ro',
    isa => Enum[qw( always hourly daily weekly monthly yearly never )],
    default => sub { 'weekly' },
);

=attr search_priority

How high should this page rank in search results compared to similar pages on
this site?  This is used in the L<sitemap.xml|http://www.sitemaps.org> to rank
individual, full pages more highly than aggregate, list pages.

Value should be between C<0.0> and C<1.0>. The default is C<0.5>.

This is only used to decide which pages are more important for the search
engine to crawl, and which pages within your site should be given to users. It
does not improve your rankings compared to other sites. See L<the sitemap
protocol|http://sitemaps.org> for details.

=cut

has search_priority => (
    is => 'ro',
    isa => Num,
    default => sub { 0.5 },
);

=method render

Render the page, using the L<template|Statocles::Page/template> and wrapping
with the L<layout|Statocles::Page/layout>.

=cut

sub render {
    my ( $self, %args ) = @_;
    my $content = $self->template->render(
        %args,
        self => $self,
        app => $self->app,
        $self->vars,
    );
    return $self->layout->render(
        %args,
        self => $self,
        app => $self->app,
        $self->vars,
        content => $content,
    );
}

1;
__END__

=head1 DESCRIPTION

A Statocles::Page takes one or more L<documents|Statocles::Document> and
renders them into one or more HTML pages using a main L<template|/template>
and a L<layout template|/layout>.

=head1 SEE ALSO

=over

=item L<Statocles::Page::Document>

A page that renders a single document.

=item L<Statocles::Page::List>

A page that renders a list of other pages.

=back

