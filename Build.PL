use strict;
use Module::Build;
use vars qw( $settings $db $user $host $password);
my $skip= 0;
if( "@ARGV" =~ /--db (\S+) --user (\S+) --host (\S+) --password (\S+)/){
        my ($db, $user, $host, $password) = ($1, $2, $3,$4);
        $skip = 1;
}
eval 'use CGI::LZE::Settings qw($settings loadSettings saveSettings)';
unless ($@) {
        loadSettings();
        *settings     = \$CGI::LZE::Settings::settings;
        $db           = $settings->{database}{name} ? $settings->{database}{name}:'LZE';
        $user         = $settings->{database}{user} ? $settings->{database}{user}:'root';
        $host         = $settings->{database}{host} ? $settings->{database}{host}:'localhost';
        $password     = $settings->{database}{password} ? $settings->{database}{password}: '';
}
unless($skip){
        $db       = Module::Build->prompt("Enter your Database Name:", $db);
        $user     = Module::Build->prompt("Enter your User Name:",     $user);
        $host     = Module::Build->prompt("Enter your host:",          $host);
        $password = Module::Build->prompt("Enter your Database password:",      $password);
}
my $class = Module::Build->subclass(
        class => "Module::Build::Custom",
        code  => qq?
use lib("lib");
use DBI::LZE;
my \$database = new DBI::LZE({name => '$db',host => '$host',user => '$user',password =>'$password' ,install => 1});
sub ACTION_build {
        my \$self = shift;
        open OUT, ">t/config.pl" or die \$!;
        print OUT "\\\$db = '$db';\\\$host = '$host';\\\$user = '$user';\\\$password ='$password';"; 
        close OUT;
        \$self->SUPER::ACTION_build;
}
sub ACTION_install {
        my \$self = shift;
        \$database->void(q/CREATE TABLE IF NOT EXISTS querys (
        title varchar(100) NOT NULL default '',
  description text NOT NULL,
  `sql` text NOT NULL,
  `return` varchar(100) NOT NULL default 'fetch_array',
  `id` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (id)
  ) ENGINE=MyISAM DEFAULT CHARSET=latin1;/);
\$self->SUPER::ACTION_install;
}
sub ACTION_uninstall {
        my \$self = shift;
        \$database->void(" DROP TABLE `querys`");
        \$self->SUPER::ACTION_uninstall;
}
sub ACTION_realclean{
        my \$self = shift;
        unlink('t/config.pl');
        \$self->SUPER::ACTION_realclean;
}
sub ACTION_test{
print "run testDb after installation $/
Don`t forgot do run realclean after testing,$/
setup will save settings as cleantext $/
";
}
sub ACTION_testdb{
        my \$self = shift;
        \$self->SUPER::ACTION_test;
}
?);
$class->new(
            module_name => 'DBI::LZE',
            requires    => {
            'DBI' => 1.50,
            'Test::More' => 0.7,
            'Test::Signature' => 1.10,
            'Module::Build' => 0.2808,
            'Test::Pod' =>  1.26,
            'Test::Pod::Coverage' =>  0.55,
             },
            ($] >= 5.005 ? (AUTHOR => 'Dirk Lindner <lindnerei@o2online.de>') : ()),
            dist_abstract      => "A simple DBI subclass",
            license            => "lgpl",
            create_makefile_pl => 'passthrough',
#             sign               => 1,
)->create_build_script;
print "
run ./Build && sudo ./Build install && ./Build testdb && ./Build realclean
Don`t forgot do run realclean after testing,
setup will save settings as cleantext
";
