use Test::More tests => 9;

{
	package Local::MyRole;
	use base qw/Object::Role/;
	sub import
	{
		my ($class, @args) = @_;
		my ($caller, %args) = __PACKAGE__->parse_arguments(undef, @args);
		my $coderef = sub { ref $_[0] or $_[0] };
		__PACKAGE__->install_method(class_name => $coderef, $caller);
	}
}

{
	package Local::MyClass;
	BEGIN { Local::MyRole->import }
	use Object::DOES;
}

my $inst = bless [], 'Local::MyClass';

ok(Local::MyRole->has_consumer('Local::MyClass'), 'Object::Role consumer registration is working.');

ok(Local::MyClass->DOES('Local::MyClass'), 'MyClass does MyClass');
ok(Local::MyClass->DOES('Local::MyRole'), 'MyClass does MyRole');
ok(Local::MyClass->can('class_name'), 'MyClass can class_name');
is(Local::MyClass->class_name, 'Local::MyClass', 'MyClass->class_name works properly');

ok($inst->DOES('Local::MyClass'), '$inst does MyClass');
ok($inst->DOES('Local::MyRole'), '$inst does MyRole');
ok($inst->can('class_name'), '$inst can class_name');
is($inst->class_name, 'Local::MyClass', '$inst->class_name works properly');
