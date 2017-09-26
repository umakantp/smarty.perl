use strict;

package Parser;

our %variable = (
    'regex' => '^\$([\w@]+)',
    'name' => 'Variable'
  );

our @tokens = (
    \%variable
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
    push @tree,parseText($self, substr($content, 0, $openTag[2]));
    $content = substr($content, $openTag[2]+length($openTag[1]));
    if (my $tag = ($openTag[0] =~ m/^\s*(\w+)(.*)$/)) {
      $tag = $1;
      my $param = $2;

    } else {
      # Variable or expression.
      @tree = (@tree, parseExpression($self, $openTag[0]));
    }
  }
  push @tree,parseText($self, $content);
  return @tree;
}

sub parseExpression {
  my ($self, $expression) = @_;

  my @tree = ();
  my $processed = '';

  while (1) {
    my $process = substr($expression, length($processed));
    if ($process eq '') {
      last;
    }
    if (substr($process, 0, 1) eq '{') {
      my @openTag = findTag($self, $process);
      $processed += $openTag[0];
      if (@openTag) {
        @tree = (@tree, parse($self, $expression));
        next;
      }
    }

    for (my $i = 0; $i < length(@tokens); $i++) {
      if ($process =~ m/$tokens[$i]{'regex'}/) {
        $processed .= $&;
        my $token = 'parse' . $tokens[$i]{'name'};
        my $data = substr($process, 0, length($&));
        #my @treeFromToken = $token->($self, $data);
        my @treeFromToken = __PACKAGE__->$token($data);
        @tree = (@tree, @treeFromToken);
        last;
      }
    }
  }

  if (length(@tree)) {
    @tree = composeExpression($self, @tree)
  }
  return @tree;
}

sub parseVariable {
  my ($self, $variable, @data) = @_;
  my $parts = $data[0];
  my %token = (
    'type' => 'variable',
    'parts' => ($1)
  );
  return \%token;
}

sub parseText {
  my ($self, $content) = @_;
  my %token = (
    'type' => 'text',
    'content' => $content
  );
  return \%token;
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
      return ($tag, $tagWithBraces, $openIndex);
    }
    # Ignore unmatched closing curly braces.
  }
  return ();
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
