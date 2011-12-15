use Test::More tests => 30;

{
	package Local::Grandparent;
	sub DOES {
		my ($self, $role) = @_;
		return 1 if $role eq 'Role8';
		return $self->SUPER::DOES($role);
	}
	# @DOES has no special meaning in this package!
	@Local::Parent::DOES = qw(Role10);
}

{
	package Local::OtherGrandparent;
	use Object::DOES -role => 'Role9';
}

{
	package Local::Parent;
	use Object::DOES -role => 'Role6';
	@Local::Parent::DOES = qw(Role7);
	@Local::Parent::ISA = qw(Local::Grandparent);
}

{
	package Local::OtherParent;
	@Local::OtherParent::ISA = qw(Local::OtherGrandparent);
}

{
	package Local::Doing;
	use Object::DOES -role => [qw/Role1 Role2 Role3/];
	@Local::Doing::DOES = qw(Role4 Role5);
	@Local::Doing::ISA = qw(Local::Parent Local::OtherParent);
}

my $obj = bless {}, 'Local::Doing';

ok($obj->DOES("Role$_"), "object does Role$_") for 1..9;
ok(!$obj->DOES("Role$_"), "NOT object does Role$_") for 10..10;
ok($obj->DOES($_), "object does $_") foreach qw/Local::Doing Local::Parent Local::Grandparent/;
ok($obj->DOES('HASH'), 'object does HASH');
ok(!$obj->DOES('ARRAY'), 'NOT object does ARRAY');

ok(Local::Doing->DOES("Role$_"), "class does Role$_") for 1..9;
ok(!Local::Doing->DOES("Role$_"), "NOT class does Role$_") for 10..10;
ok(Local::Doing->DOES($_), "class does $_") foreach qw/Local::Doing Local::Parent Local::Grandparent/;
ok(!Local::Doing->DOES('HASH'), 'NOT class does HASH');
ok(!Local::Doing->DOES('ARRAY'), 'NOT class does ARRAY');
