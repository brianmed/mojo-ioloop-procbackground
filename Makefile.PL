use 5.016003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mojo::IOLoop::ProcBackground',
    VERSION_FROM      => 'lib/Mojo/IOLoop/ProcBackground.pm', # finds $VERSION
    PREREQ_PM         => {"Mojolicious" => 5.00, "Proc::Background" => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Mojo/IOLoop/ProcBackground.pm', # retrieve abstract from module
       AUTHOR         => 'Brian <bpmedley@cpan.org>') : ()),
);
