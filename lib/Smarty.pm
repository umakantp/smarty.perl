use strict;
use Parser;
use Processor;

package Smarty;

our @templateDir = ();

sub new {
  my $class = shift;
  my $self = {
    parentTemplate => '',
    @templateDir => ()
  };

  bless $self, $class;
  return $self;
}

sub addTemplateDir {
  my ($self, $templateDir) = @_;
  push @templateDir,$templateDir;
}

sub display {
  my ($self, $parentTemplate,  $data) = @_;

  my $found = 0;
  foreach my $dir(@templateDir) {
    if (-e $dir.'\\'.$parentTemplate) {
      $found = 1;
      $parentTemplate = $dir.'\\'.$parentTemplate
    }
  }

  if ($found == 0) {
    my $e = $parentTemplate.' does not exists.';
    die $e;
  }

  $self->{$parentTemplate} = $parentTemplate;

  my $content = '';
  open(my $fh, '<:encoding(UTF-8)', $parentTemplate);
  while (my $row = <$fh>) {
    $content = $content . $row;
  }

  my $pa = new Parser();
  my @tree = $pa->init($content);

  my $pr = new Processor();
  my $output = $pr->render(\@tree, $data);
  return $output;
}

1;
