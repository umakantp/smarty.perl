use strict;
use warnings;
use diagnostics;
use lib 'E:\exp\smarty.perl\smarty.perl\lib';
use Smarty;

my $smarty = new Smarty();
$smarty->addTemplateDir('E:\exp\smarty.perl\smarty.perl\example');

my %data = (
  'name' => 'world!'
);
print $smarty->display('test.tpl', \%data);
