# Copyright (c) 1998-2002 by Jonathan Swartz. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package HTML::Mason::Buffer;

use strict;

use HTML::Mason::Container;
use base qw(HTML::Mason::Container);

use HTML::Mason::Exceptions( abbr => ['param_error'] );

use Params::Validate qw(:all);
Params::Validate::validation_options( on_fail => sub { param_error join '', @_ } );

use HTML::Mason::MethodMaker
    ( read_only => [ qw( sink
			 parent
                         filter
			 ignore_flush
		       ) ],
    );

__PACKAGE__->valid_params
    (
     sink         => { parse => 'code', type => SCALARREF | CODEREF, optional => 1,
		       descr => "A subroutine or scalar reference that will receive the output stream",
		       public => 0 },
     parent       => { isa => 'HTML::Mason::Buffer', optional => 1,
		       descr => "A parent buffer of the current buffer",
		       public => 0 },
     ignore_flush => { parse => 'boolean', type => SCALAR, default => 0,
		       descr => "Whether the flush() method is a no-op or actually flushes content",
		       public => 0 },
     filter       => { type => CODEREF, optional => 1,
		       descr => "A subroutine through which all output should pass",
		       public => 0 },
    );

sub new
{
    my $class = shift;
    my @args = $class->create_contained_objects(@_);

    my $self = bless { validate( @args, $class->validation_spec ) }, $class;

    $self->_initialize;
    return $self;
}

sub _initialize
{
    my $self = shift;

    if ( defined $self->{sink} )
    {
	if ( UNIVERSAL::isa( $self->{sink}, 'SCALAR' ) )
	{
	    # convert scalarref to a coderef for efficiency
	    my $b = $self->{buffer} = $self->{sink};
	    $self->{sink} = sub { for (@_) { $$b .= $_ if defined } };
	}
    }
    else
    {
	# create an empty string to use as buffer
	my $buf = '';
	my $b = $self->{buffer} = \$buf;
	$self->{sink} = sub { for (@_) { $$b .= $_ if defined } };
    }

    $self->{ignore_flush} = 1 unless $self->{parent};
}

sub new_child
{
    my $self = shift;
    return ref($self)->new( parent => $self, @_ );
}

sub receive
{
    my $self = shift;
    $self->sink->(@_) if @_;
}

sub flush
{
    my $self = shift;
    return if $self->ignore_flush;

    my $output = $self->output;
    return unless defined $output && $output ne '';

    $self->parent->receive( $output ) if $self->parent;
    $self->clear;
}

sub clear
{
    my $self = shift;
    return unless exists $self->{buffer};
    ${$self->{buffer}} = '';
}

sub output
{
    my $self = shift;
    return unless exists $self->{buffer};
    my $output = ${$self->{buffer}};
    return $self->filter->( $output ) if $self->filter;
    return $output;
}

1;

__END__

=head1 NAME

HTML::Mason::Buffer - Objects for Handling Component Output

=head1 SYNOPSIS

   ???

=head1 DESCRIPTION

Mason's buffer objects handle all output generated by components.
They are used to implement C<< <%filter> >> blocks, the C<< $m->scomp >>
method, the C<store> component call modifier, and content-filtering
component feature.

Buffers can either store output in a scalar, internally, or they can
be given a callback to call immediately when output is generated.

=head1 CONSTRUCTOR

...

=head1 METHODS

...

=cut
