use strict;

package Parser;

our $loopish = 1;

our %variable = (
  'regex' => '^\$([\w@]+)',
  'name' => 'Variable'
);

our %closeArray = (
  'regex' => '^\]',
  'name' => 'CloseArray'
);

our %number = (
  'regex' => '^[\d.]+',
  'name' => 'Number'
);

our %static = (
  'regex' => '^\w+',
  'name' => 'Static'
);

our @tokens = (
  \%variable,
  \%closeArray,
  \%number,
  \%static
);

sub new {
  my $class = shift;
  my $self = {};

  bless $self, $class;
  return $self;
}

sub init {
  my ($self, $content) = @_;
  $content = removeComments($self, $content);
  $content = fixNewLines($self, $content);

  # TODO apply pre filters.
  my @tree = parse($self, $content);
  return @tree;
}

sub parse {
  my ($self, $content) = @_;

  my @tree = ();
  while (my @openTag = findTag($self, $content)) {
    push @tree,parseText($self, substr($content, 0, $openTag[3]));
    $content = substr($content, $openTag[3]+length($openTag[2]));
    if (my $tag = ($openTag[0] =~ m/^\s*(\w+)(.*)$/)) {
      $tag = $1;
      my $param = $2;

    } else {
      # Variable or expression.
      my @expressionTree = parseExpression($self, $openTag[1], 0);
      my $tempTreeRef = $expressionTree[0];
      @tree = (@tree, @$tempTreeRef);
    }
  }
  push @tree,parseText($self, $content);
  return @tree;
}

sub parseExpression {
  my ($self, $expression, $ifCompose) = @_;

  my @tree = ();
  my $processed = '';

  while (1) {
    $loopish++;
    if ($loopish == 10) {
      die 1;
    }
    my $process = '';
    if (length($expression) > length($processed)) {
      $process = substr($expression, length($processed));
    } else {
      last;
    }
    print "Came for processing: ".$process."\n";
    if (substr($process, 0, 1) eq '{') {
      my @openTag = findTag($self, $process);
      $processed += $openTag[0];
      if (@openTag) {
        # do merge by reference.
        @tree = (@tree, parse($self, $expression));
        next;
      }
    }

    for (my $i = 0; $i <= $#tokens; $i++) {
      if ($process =~ m/$tokens[$i]{'regex'}/) {
        print "so far processed before: ".$processed."\n";
        $processed .= $&;
        print "so far processed after: ".$processed."\n";
        my $token = 'parse' . $tokens[$i]{'name'};
        my $data = substr($process, length($&));
        print "token calling with data: ".$token."==".$data."\n";
        my @dataFromToken = __PACKAGE__->$token($data);
        my $tempTreeRef = $dataFromToken[0];
        @tree = (@tree, $tempTreeRef);
        $processed .= $dataFromToken[1];
        last;
      }
    }
  }

  if ($ifCompose != 1 and length(@tree)) {
    @tree = composeExpression($self, @tree)
  }
  return (\@tree, $processed);
}

sub parseVariable {
  my ($self, $partialVariable) = @_;
  my $processed = '';
  my @parts = ($1);
  my $find = '^(\.|\s*->\s*|\s*\[\s*)';
  while ($partialVariable =~ /$find/) {
    $partialVariable = substr($partialVariable, length($&));
    $processed .= $&;
    print "processed//variable sending to process: ".$processed."//".$partialVariable."\n";
    my @treeTemp = parseExpression($self, $partialVariable, 1);
    my $actualTreeRef = $treeTemp[0];
    my @actualTree = @$actualTreeRef;
    $processed .= $treeTemp[1];
    print "final processed becomes: ".$processed."\n";
    if (@actualTree) {
      for (my $j=0; $j < length(@actualTree); $j++) {
        my %node = %{$actualTree[$j]};
        if ($node{'type'} eq 'text') {
          push @parts, $node{'content'};
        }
      }
    }
    if ($partialVariable =~ /\s*\]/) {
      $processed .= $&;
      $partialVariable = substr($partialVariable, length($&));
    }
  }
  my %varToken = (
    'type' => 'variable',
    'parts' => \@parts
  );
  return (\%varToken, $processed);
}

sub parseNumber {
  my ($self, $content) = @_;
  my %numberToken = (
    'type' => 'text',
    'content' => $&
  );
  return (\%numberToken, '');
}

sub parseCloseArray {
  my ($self, $content) = @_;
  my %closeArrayToken = (
    'type' => 'ignore',
    'content' => $&
  );
  print 'close array is adding '.$&."\n";
  return (\%closeArrayToken, '');
}

sub parseStatic {
  my ($self, $content) = @_;
  my %staticToken = (
    'type' => 'text',
    'content' => $&
  );
  return (\%staticToken, '');
}

sub parseText {
  my ($self, $content) = @_;
  my %textToken = (
    'type' => 'text',
    'content' => $content
  );
  return \%textToken;
}

sub composeExpression {
  my ($self, @tree) = @_;

  return @tree;
}

sub findTag {
  my ($self, $content) = @_;
  # TODO Handler auto literal.
  my $openIndex = index($content, '{');
  if ($openIndex != -1) {
    my $remain = substr($content, $openIndex + 1); #+1 to omit {
    my $closeIndex = index($remain, '}');
    if ($closeIndex != -1) {
      my $tag = substr($remain, 0, $closeIndex);
      my $tagWithBraces = '{' . $tag . '}';
      return ($tag, trim($tag), $tagWithBraces, $openIndex);
    }
    # Ignore unmatched closing curly braces.
  }
  return ();
}
sub trim {
  my $s = shift;
  $s =~ s/^\s+|\s+$//g;
  return $s
}

sub replace {
  my ($self, $from, $to, $string) = @_;
  $string =~s/$from/$to/ig; #case-insensitive/global (all occurrences)

  return $string;
}

sub fixNewLines {
  my ($self, $content) = @_;
  $content = replace($self, "\\r\\n", "\\n", $content);
  return $content;
}

sub removeComments {
  my ($self, $content) = @_;
  while (1) {
    my $openIndex = index($content, '{*');
    if ($openIndex != -1) {
      my $remain = substr($content, $openIndex+2); #+2 to omit {*
      my $closeIndex = index($remain, '*}');
      if ($closeIndex == -1) {
        die 'Unclosed {*';
      } else {
        my $beforeContent = substr($content, 0, $openIndex);
        my $afterContent = substr($remain, $closeIndex+2); #+2 to omit *}
        $content = $beforeContent . $afterContent;
      }
    } else {
      last;
    }
  }
  return $content;
}


1;
