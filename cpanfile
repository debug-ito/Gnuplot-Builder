
on 'test' => sub {
    requires 'Test::More' => "0";
    requires 'Test::MockObject::Extends' => "0";
    requires 'Test::Identity' => "0";
};

on 'configure' => sub {
    requires 'Module::Build', '0.42';
    requires 'Module::Build::Pluggable', '0.09';
    requires 'Module::Build::Pluggable::CPANfile', '0.02';
};
