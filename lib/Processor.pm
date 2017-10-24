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

  my $content = '';
  for (my $i = 0; $i <= $#tree; $i++) {
    my $nodeRef = $tree[$i];
    my %node = %{$nodeRef};

    if ($node{'type'} eq 'text') {
      $content = $content . $node{'content'};
    } elsif ($node{'type'} eq 'variable') {
      $content = $content . processVariable($self, $nodeRef, $dataRef);
    }
  }
  return $content;
}

sub processVariable()  {
  my ($self, $nodeRef, $lastValue) = @_;
  my %node = %{$nodeRef};
  for (my $i=0; $i<=length($node{'parts'}); $i++) {
    my $t = $node{'parts'};
    my @tt = @$t;
    if(ref($lastValue) eq 'ARRAY') {
      my @a = @$lastValue;
      $lastValue = {$a[$tt[$i]]};
    } elsif(ref($lastValue) eq 'HASH') {
      my %h = %{$lastValue};
      $lastValue = $h{$tt[$i]};
    }
  }
  return $lastValue;
}

1;
