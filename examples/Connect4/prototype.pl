=pod

  EMPTY  = 0
  PLAYER = 1
  CPU    = 2

  Main:

    play()
      |
      +-- randomly choose the starting side
      |
      +-- alternate Player and CPU turns
            |
            +-- Player turn:
            |     input_col -> drop PLAYER
            |       +-- full column: retry input
            |     display_board -> won(PLAYER)?
            |       +-- yes: PLAYER WINS
            |
            +-- CPU turn:
                  cpu_move()
                    +-- no playable column: NO WINS
                  drop CPU -> display_board -> won(CPU)?
                    +-- yes: CPU WINS
                  board_full()?
                    +-- yes: NO WINS

  Board:

    @i
    get_cell(row,col)
    set_cell(row,col,value)
    drop(col,player)
    board_full()
      +-- returns true when every top-row cell is occupied

  AI:

    cpu_move()
      |
      +-- CPU wins immediately   +1000
      +-- Player-blocking move    +500
      +-- column 4                  +4
      +-- column 3 or 5             +2
      +-- otherwise                  0

  Rules:

    won(player)
      +-- horizontal
      +-- vertical
      +-- diagonal /
      +-- diagonal \

  UI:

    input_col()
    display_board()

=cut

use strict;
use warnings;

use Test::More;

# define constants for the different types of cells on the board
use constant {
  EMPTY  => 0,
  PLAYER => 1,
  CPU    => 2,
};

# rows of the board, each represented as a 7-digit number (columns 1-7)
my @i = (0) x 6;

# get and set the value of a cell in the board
sub get_cell {    # $value ($row,$col)
  my ( $row, $col ) = @_;
  my $pos = 10 ** ( 7 - $col );
  return int( $i[$row - 1] / $pos ) % 10;
}

sub set_cell {    # void ($row,$col,$value)
  my ( $row, $col, $value ) = @_;
  my $pos = 10 ** ( 7 - $col );
  my $old = get_cell( $row, $col );
  $i[$row - 1] += ( $value - $old ) * $pos;
  return;
}

# display the board to the user
sub display_board {    # void ()
  for my $row ( 1 .. 6 ) {
    my $display = $row + $i[$row - 1] / 1e7;
    printf( "%.7f\n", $display );       # FIX
    select undef, undef, undef, 0.3;    # PSE
  }
  return;
}

# get the player's input for the column to drop a piece into the board
sub input_col {    # $col ()
  while (1) {
    print "COL=";

    my $col = <STDIN>;

    next unless defined $col;
    chomp $col;
    next unless $col ge 1 && $col le 7;

    return int $col;
  }
}

# drop a piece into the board for the given player and 
# return the row it lands in, or 0 if the column is full
sub drop {    # $row ($col,$player)
  my ( $col, $player ) = @_;

  for my $row ( reverse 1 .. 6 ) {
    next if get_cell( $row, $col );
    set_cell( $row, $col, $player );
    return $row;
  }

  return 0;
}

# check whether every column is full
sub board_full {    # $bool ()
  for my $col ( 1 .. 7 ) {
    return 0 if get_cell( 1, $col ) == EMPTY;
  }

  return 1;
}

# check if the given player has won the game
sub won {    # $bool ($player)
  my ($player) = @_;

  my ( $R, $A, $C, $X, $Y );

  #              R  A  C  X   Y
  # Horizontal   6  1  4  0   1
  # Vertical     3  1  7  1   0
  # Diagonal \   3  1  4  1   1
  # Diagonal /   3  4  7  1  -1

HORIZONTAL:
  ( $R, $A, $C, $X, $Y ) = ( 6, 1, 4, 0, 1 );
  goto CHECK;

VERTICAL:
  ( $R, $A, $C, $X, $Y ) = ( 3, 1, 7, 1, 0 );
  goto CHECK;

DIAGONAL_DOWN:
  ( $R, $A, $C, $X, $Y ) = ( 3, 1, 4, 1, 1 );
  goto CHECK;

DIAGONAL_UP:
  ( $R, $A, $C, $X, $Y ) = ( 3, 4, 7, 1, -1 );

CHECK:
  for my $r ( 1 .. $R ) {
    next if $i[$r - 1] == 0;

    for my $c ( $A .. $C ) {
      return 1
        if get_cell( $r,          $c          ) == $player
        && get_cell( $r + $X,     $c + $Y     ) == $player
        && get_cell( $r + 2 * $X, $c + 2 * $Y ) == $player
        && get_cell( $r + 3 * $X, $c + 3 * $Y ) == $player;
    }
  }

  goto VERTICAL      if $X == 0;
  goto DIAGONAL_DOWN if $Y == 0;
  goto DIAGONAL_UP   if $X == $Y;

  return 0;
}

# determine the best move for the CPU based on the current board state
sub cpu_move {    # $col ()
  my $best_value = -9999;
  my $best_col   = 0;

  for my $col ( 1 .. 7 ) {
    my $row = drop( $col, CPU );

    next unless $row;

    my $value = 0;

    # Prefer the center.
    $value += 4 if $col == 4;
    $value += 2 if $col == 3 || $col == 5;

    # Check an immediate CPU win.
    $value += 1000 if won(CPU);

    # Undo CPU move.
    set_cell( $row, $col, EMPTY );

    # Check whether this move blocks an immediate player win.
    $row = drop( $col, PLAYER );
    $value += 500 if won(PLAYER);

    # Undo player move.
    set_cell( $row, $col, EMPTY );

    if ( $value > $best_value ) {
      $best_value = $value;
      $best_col   = $col;
    }
  }

  return $best_col;
}

# main game loop for playing Connect4
sub play {    # void ()
  @i = (0) x 6;
  my $cpu_turn = int( rand(2) );

  while (1) {
    if ($cpu_turn) {
      my $col = cpu_move();

      # No valid column means that the board is full.
      if (!$col) {
        print "NO WINNER\n";
        last;
      }

      my $row = drop( $col, CPU );

      print "SET=$col\n";
      display_board();

      if ( won(CPU) ) {
        print "I WIN\n";
        last;
      }

      if ( board_full() ) {
        print "NO WINNER\n";
        last;
      }
    }
    else {
      my $col = input_col();
      my $row = drop( $col, PLAYER );

      if (!$row) {
        print "COLUMN FULL\n";
        next;
      }

      display_board();

      if ( won(PLAYER) ) {
        print "YOU WIN\n";
        last;
      }
    }

    $cpu_turn = !$cpu_turn;
  }

  return;
}

# test cases for the Connect4 game

subtest 'horizontal' => sub {
  @i = ( 0, 0, 0, 0, 0, 1111000 );

  ok( won(PLAYER), 'player wins' );
};

subtest 'vertical' => sub {
  @i = ( 0, 0, 1000000, 1000000, 1000000, 1000000 );

  ok( won(PLAYER), 'player wins' );
};

subtest 'diagonal down right' => sub {
  @i = ( 0, 0, 1000000, 100000, 10000, 1000 );

  ok( won(PLAYER), 'player wins' );
};

subtest 'diagonal down left' => sub {
  @i = ( 0, 0, 1000, 10000, 100000, 1000000 );

  ok( won(PLAYER), 'player wins' );
};

subtest 'no winner' => sub {
  @i = ( 0, 0, 0, 0, 0, 1110000 );

  ok( !won(PLAYER), 'three are not enough' );
};

subtest 'cpu horizontal' => sub {
  @i = ( 0, 0, 0, 0, 0, 2222000 );

  ok( won(CPU),     'cpu wins' );
  ok( !won(PLAYER), 'player does not win' );
};

subtest 'horizontal right edge' => sub {
  @i = ( 0, 0, 0, 0, 0, 1111 );

  ok( won(PLAYER), 'player wins at right edge' );
};

subtest 'full board without winner' => sub {
  @i = (
    1212121,
    2121212,
    2121212,
    1212121,
    1212121,
    2121212,
  );

  ok( !won(PLAYER), 'player does not win' );
  ok( !won(CPU),    'cpu does not win' );
  ok( board_full(), 'board is full' );
};

subtest 'cpu fills last cell without winning' => sub {
  @i = (
    1212120,
    2121212,
    2121212,
    1212121,
    1212121,
    2121212,
  );

  ok( !board_full(), 'board still has one playable cell' );
  is( drop( 7, CPU ), 1, 'CPU fills the top cell' );
  ok( board_full(), 'board is full after CPU move' );
  ok( !won(CPU), 'CPU has not won' );
  ok( !won(PLAYER), 'player has not won' );
};

subtest 'cpu takes immediate win' => sub {
  @i = (
    0,
    0,
    0,
    0,
    0,
    2220000,
  );

  is( cpu_move(), 4, 'cpu completes four' );
};

subtest 'cpu blocks immediate player win' => sub {
  @i = (
    0,
    0,
    0,
    0,
    0,
    1110000,
  );

  is( cpu_move(), 4, 'cpu blocks player' );
};

subtest 'cpu prefers center on empty board' => sub {
  @i = (0) x 6;

  is( cpu_move(), 4, 'cpu chooses center' );
};

done_testing;

play();
