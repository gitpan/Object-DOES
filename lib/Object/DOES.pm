package Object::DOES;

use 5.006;
use strict;

BEGIN {
	$Object::DOES::AUTHORITY = 'cpan:TOBYINK';
	$Object::DOES::VERSION   = '0.001';
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
			return 4 if $_->DOES($role);
		}
		
		return 5 if $invocant->isa($role);
		
		if ($role->DOES('Object::Role') and (my $check = $role->can('has_consumer')))
		{
			foreach (Class::ISA::super_path($package), 'UNIVERSAL')
			{
				return 6 if $role->$check($_);
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

