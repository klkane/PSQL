use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PSQL',
    VERSION_FROM      => 'lib/PSQL.pm', # finds $VERSION
    PREREQ_PM         => { 'Text::Table' => 0,
                           'Text::ASCIITable' => 0,
                           'Term::ReadLine' => 0,
                           'Data::Dumper' => 0,
                           'Term::Screen::Uni' => 0,
                           'Module::Load' => 0 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PSQL.pm', # retrieve abstract from module
       AUTHOR         => 'Kevin L. Kane<kevin.kane@gmail.com>') : ()),
);
