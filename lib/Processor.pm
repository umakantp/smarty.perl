use strict;

package Processor;

sub new {
  my $class = shift;
  my $self = {};

  bless $self, $class;
  return $self;
}

sub render {
  my ($self, $treeRef, $dataRef) = @_;
  my @tree = @$treeRef;
  my %data = %{$dataRef};
  my $content = '';
  for (my $i = 0; $i <= $#tree; $i++) {
    my $nodeRef = $tree[$i];
    my %node = %{$nodeRef};

    if ($node{'type'} eq 'text') {
      $content = $content . $node{'content'};
    }
    if ($node{'type'} eq 'variable') {
      $content = $content . $data{$node{'parts'}};
    }
  }
  return $content;
}

1;
