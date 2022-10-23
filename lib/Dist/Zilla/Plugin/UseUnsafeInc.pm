use strict;
use warnings;
package Dist::Zilla::Plugin::UseUnsafeInc;
# vim: set ts=8 sts=2 sw=2 tw=115 et :
# ABSTRACT: Indicates in metadata the value of PERL_USE_UNSAFE_INC to use during installation
# KEYWORDS: metadata PERL_USE_UNSAFE_INC INC distribution testing compatibility environment security

our $VERSION = '0.002';

use Moose;
with 'Dist::Zilla::Role::MetaProvider',
  'Dist::Zilla::Role::AfterBuild',
  'Dist::Zilla::Role::BeforeRelease';

use namespace::autoclean;

has dot_in_INC => (
    is => 'ro', isa => 'Bool',
    required => 1,
);

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        dot_in_INC => $self->dot_in_INC ? 1 : 0,
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };

    return $config;
};

sub metadata
{
    my $self = shift;
    +{ x_use_unsafe_inc => $self->dot_in_INC ? 1 : 0 };
}

sub after_build
{
    my $self = shift;

    # this is kind of kludgy but we just need to have this set before TestRunners run.
    $self->log_debug([ 'Setting PERL_USE_UNSAFE_INC = %s for local testing...', $self->dot_in_INC ]);
    $ENV{PERL_USE_UNSAFE_INC} = $self->dot_in_INC;
}

sub before_release
{
    my $self = shift;

    $self->log('DZIL_ANY_PERL set: skipping perl version check'), return
        if $ENV{DZIL_ANY_PERL};

    $self->log_fatal('Perl must be 5.025007 or newer to test with PERL_USE_UNSAFE_INC -- disable check with DZIL_ANY_PERL=1')
        if "$]" < 5.025007;
}

__PACKAGE__->meta->make_immutable;
__END__

=pod

=head1 SYNOPSIS

In your F<dist.ini>:

    ; this distribution still requires . to be in @INC
    [UseUnsafeInc]
    dot_in_INC = 1

or:

    ; this distribution does not need . to be in @INC
    [UseUnsafeInc]
    dot_in_INC = 0

=head1 DESCRIPTION

=for Pod::Coverage metadata after_build before_release

This is a L<Dist::Zilla> plugin that populates the C<x_use_unsafe_inc> key in your distribution metadata. This
indicates to components of the toolchain that C<PERL_USE_UNSAFE_INC> should be set to a certain value during
installation and testing.  If C<PERL_USE_UNSAFE_INC> has already been set in the environment, it is unchanged, but
the metadata is respected at a higher precedence than any setting that other tools e.g. L<Test::Harness> might have
done.

The environment variable is also set in L<Dist::Zilla> while building and testing the distribution, to ensure
that local testing behaves in an expected fashion.

Additionally, the release must be performed using a Perl version that supports C<PERL_USE_UNSAFE_INC> (that is,
5.26), to further guarantee test integrity. To bypass this check, set C<DZIL_ANY_PERL=1> in the environment.

=head1 CONFIGURATION OPTIONS

=head2 C<use_unsafe_inc>

This configuration value must be set in your F<dist.ini>, to either 0 or 1.  C<PERL_USE_UNSAFE_INC> will be set to
the same value by tools that support it.

=head2 C<DZIL_ANY_PERL>

When this environment variable is true, the Perl version check at release time (see above) is skipped.

=head1 BACKGROUND

=head1 SEE ALSO

=for :list
* L<perldelta/'.' and @INC>
* L<Dist::Zilla::Plugin::EnsureLatestPerl>

=cut
