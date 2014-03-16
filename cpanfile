
requires 'List::Util' => "1.28";
requires 'Scalar::Util' => "0";
requires "overload" => "0";
requires "IPC::Open3" => "0";
requires "POSIX" => "0";
requires "Try::Tiny" => "0";
requires "parent" => "0";
requires "File::Spec" => "0";

on 'test' => sub {
    requires 'Test::More' => "0";
    requires 'Test::Identity' => "0";
    requires 'Test::Memory::Cycle' => "0";
};

on 'configure' => sub {
    requires 'Module::Build', '0.42';
    requires 'Module::Build::Pluggable', '0.09';
    requires 'Module::Build::Pluggable::CPANfile', '0.02';
};
