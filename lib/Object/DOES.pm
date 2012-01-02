package Object::DOES;

use 5.006;
use strict;

BEGIN {
	$Object::DOES::AUTHORITY = 'cpan:TOBYINK';
	$Object::DOES::VERSION   = '0.002';
}

use Class::ISA qw//;
use Object::AUTHORITY;

use base qw/Object::Role/;

sub import
{
	my ($self, @args) = @_;
	my ($caller, %args) = __PACKAGE__->parse_arguments('-default' => @args);
	
	my $sub = sub 
	{
		my ($invocant, $role) = @_;
		
		return 1 if $role eq 'Object::DOES';
		
		my $package = ref($invocant) || $invocant;
		
		return 2
			if exists $args{'-role'}
			&& Object::AUTHORITY::reasonably_smart_match($role, $args{'-role'});
		
		my $does_array = do {
			no strict 'refs';
			[ @{"$package\::DOES"} ? @{"$package\::DOES"} : qw// ]
			};
		return 3
			if Object::AUTHORITY::reasonably_smart_match($role, $does_array);
		
		foreach (Class::ISA::super_path($package), 'UNIVERSAL')
		{
			my $method = $_->can('DOES');
			next unless $method;
			return 4 if $_->$method($role);
		}
		
		return 5 if $invocant->isa($role);
		
		if ($role->isa('Object::Role')
		or do { my $d = $role->can('DOES'); (defined $d) ? $role->$d('Object::Role') : 0 })
		{
			if (my $check = $role->can('has_consumer'))
			{
				foreach ($package, Class::ISA::super_path($package), 'UNIVERSAL')
				{
					return 6 if $role->$check($_);
				}
			}
		}
		
		return;
	};
	
	__PACKAGE__->install_method(DOES => $sub, $caller);
}

1;

__END__

=head1 NAME

Object::DOES - override UNIVERSAL::DOES easily

=head1 SYNOPSIS

 {
   package Test::Mock::LWP::Simple;
   use Object::DOES;
   our @DOES = qw(LWP::Simple);
   sub get { ... }
   sub head { ... }
 }
 
 foreach my $package (qw/LWP::Simple Test::Mock::LWP::Simple CGI/)
 {
   if ($package->DOES('LWP::Simple'))
   {
     say "$package does LWP::Simple";
   }
}

=head1 DESCRIPTION

L<UNIVERSAL> says: I<<
"DOES" and "isa" are similar, in that if either is true, you know
that the object or class on which you call the method can perform
specific behavior.  However, "DOES" is different from "isa" in that
it does not care how the invocant performs the operations, merely
that it does.  ("isa" of course mandates an inheritance
relationship.  Other relationships include aggregation, delegation,
and mocking.) >>

In Perl 5.10, C<UNIVERSAL::DOES> was introduced, which recognises that
you sometimes need to indicate (and test) whether a class performs
a particular role, but without caring if it uses inheritance to
achieve it. (In fact, it is almost always more useful to check C<DOES>
than C<isa>!)

However, the built-in C<UNIVERSAL::DOES> is essentially just a clone
of C<UNIVERSAL::isa>. The intention is that if you want to indicate
your module does a role, you must provide a custom C<DOES> method for
your package. Fair enough, but this leads to boiler-plate code along
the lines of:

  sub DOES
  {
    my ($invocant, $role) = @_;
    return 1 if $role eq 'Foo::Version1';
    return 1 if $role eq 'Foo::Version2';
    return $invocant->SUPER::DOES($role);
  }

But you have to be careful to get things right. At first glance the
code above looks fine. But imagine our package also inherits from two
other packages Bar and Baz. And imagine that Bar and Baz both provide
custom C<DOES> methods of their own. C<SUPER::DOES> will only call one
of those custom C<DOES> methods.

This module should help you avoid the headaches of considering all
the edge cases. All you need to do is:

  use Object::DOES;
  our @DOES = qw(Role1 Role2 Role3); # etc

There is also an alternative syntax which may be more attractive to
some people:

  use Object::DOES -role => [qw/Role1 Role2 Role3/];

=head1 USING WITH OTHER MODULES

=head2 Object::Role

Any roles that use the framework provided by L<Object::Role> will
automatically play nice with Object::DOES. For example:

  {
    package Example::MyRole;
    use base qw/Object::Role/;
    sub import {
      ...
      __PACKAGE__->install_method(foobar => $coderef, $caller);
    }
  }
  
  {
    package Example::MyClass;
    use Example::MyRole;
    use Object::DOES -role => 'Example::MyOtherRole';
    sub new { ... }
  }
  
  my $obj = Example::MyClass->new;
  
  use Test::More tests => 5;
  ok $new->isa('Example::MyClass');
  ok $new->does('Example::MyClass');
  ok $new->does('Example::MyRole');
  ok $new->does('Example::MyOtherRole');
  ok $new->can('foobar');

=head1 CAVEATS

This module is designed to help classes override UNIVERSAL::DOES, but it
makes no assumption that UNIVERSAL::DOES actually exists. UNIVERSAL::DOES
was introduced in Perl 5.10, but there is a CPAN module L<UNIVERSAL::DOES>
that provides an implementation for earlier versions of Perl. The simple
shim

  *UNIVERSAL::DOES = sub { shift->isa(@_) }
      unless defined &UNIVERSAL::DOES;

... is often sufficient if you don't wish to introduce a depedency on
L<UNIVERSAL::DOES> or Perl 5.10. However, Object::DOES will I<not> do
this for you.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Object-DOES>.

=head1 SEE ALSO

L<UNIVERSAL>, L<UNIVERSAL::DOES>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

