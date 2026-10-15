# Connect Four for the HP-35s

A playable Connect Four implementation for the HP-35s programmable calculator.

The program is intentionally designed around the capabilities and limitations of the HP-35s. The primary goal is not execution speed, but a reasonably compact program that can still be entered, inspected, and maintained directly on the calculator.

A Perl prototype was used to develop and test the board representation, game rules, and CPU strategy before translating the program to HP-35s instructions. 

To play on the calculator, run the program from label `C`. Enter a column from 1 through 7 when prompted with `COL=`. The calculator displays the board one row at a time and shows the CPU's selected column with `SET=`.


## Game

The game uses the standard Connect Four board:

- 7 columns
- 6 rows
- player pieces are represented by `1`
- CPU pieces are represented by `2`
- empty cells are represented by `0`

The player selects a column from 1 through 7. A piece falls into the lowest free cell of that column.

At the start of each game, the program randomly chooses whether the player or the CPU moves first. The sides then alternate turns. After each move, the board is checked for a win.

The game ends when either side connects four pieces or when all cells are occupied without a winner. In the latter case, the calculator displays `NO WINNER`.


## Board Representation

The board is stored in six indirect registers:

    I1 .. I6

Each register contains one row encoded as a seven-digit decimal number. Each digit represents one board cell:

    0 = empty
    1 = player
    2 = CPU

For example:

    0012100

represents:

    column:  1 2 3 4 5 6 7
    cell:    0 0 1 2 1 0 0

Rows are numbered from 1 at the top to 6 at the bottom.

When a piece is dropped, the program searches from row 6 upward until it finds the first empty cell.


## Board Display

The HP-35s display is also used as a compact representation of the board.

Each row is displayed as its row number followed by the seven encoded board
cells:

    1.0002000
    2.0001000
    3.0002200
    4.0012100
    5.0021100
    6.0212100

The integer part identifies the row. The seven digits after the decimal point represent columns 1 through 7.

This avoids constructing a graphical board and keeps the displayed form close to the internal representation.


## Program Structure

The main game loop is intentionally simple:

    play
    |
    +-- choose starting side at random
    |
    +-- player turn <----+
    |
    +-- CPU turn --------+
    |
    +-- repeat until game ends

A player turn reads a column with `input_col`, drops the piece, displays the board, and checks for a win. A CPU turn selects a column with `cpu_move`, drops the piece, displays the board, and checks for a win.

A player move into a full column is rejected and input is requested again. The program checks for a full board after both player and CPU moves, so a draw is detected regardless of who fills the last cell.

If `cpu_move` cannot find any playable column, the board is full and the game ends without a winner. `board_full` checks the top cell of each column after a CPU move.


## Board Operations

The board is accessed through three main routines:

    get_cell
    set_cell
    drop
    board_full

`get_cell` extracts one decimal digit from a board row.

`set_cell` replaces one decimal digit without rebuilding the complete row.

`drop` searches from the bottom upward for the first empty cell and places the requested piece there.

`board_full` checks whether every top-row cell is occupied, which means no column can accept another piece.

The same board operations are also used while the CPU simulates candidate moves.


## Win Detection

A win consists of four equal non-empty cells in one of four directions:

    horizontal      (0,  1)
    vertical        (1,  0)
    diagonal \      (1,  1)
    diagonal /      (1, -1)

The valid starting ranges differ for each direction:

    horizontal      rows 1..6, columns 1..4
    vertical        rows 1..3, columns 1..7
    diagonal \      rows 1..3, columns 1..4
    diagonal /      rows 1..3, columns 4..7

All four cases use the common `test_four` routine.

`test_four` starts at `(row,column)` and checks four cells while advancing by the supplied `(row step,column step)` pair.

The result of `won` is returned through flag 0:

    flag 0 clear    no win
    flag 0 set      win


## CPU Strategy

The CPU uses a compact heuristic move evaluator suitable for a programmable calculator. It uses the weights 1000, 500, 4, and 2 for immediate wins, blocks, center, and near-center moves respectively.

The general strategy follows common simple Connect Four heuristics: take an immediate winning move, prevent an immediate opponent win, and otherwise prefer positions near the center of the board.

This implementation assigns the following weights:

    immediate CPU win              +1000
    blocks an immediate player win  +500
    center column (4)                 +4
    adjacent column (3 or 5)          +2
    other columns                      0

The numerical weights are implementation choices. They establish the priority

    win > block > position

without requiring a deeper game-tree search.

For every candidate column the CPU:

1. adds the positional score,
2. simulates a CPU move,
3. checks for an immediate CPU win,
4. undoes the move,
5. simulates a player move in the same column,
6. checks whether that move would give the player an immediate win,
7. undoes the move,
8. compares the resulting score with the best score so far.

Only a strictly higher score replaces the current best move. For a given board state, the CPU's move selection is deterministic.

Columns are examined from 1 through 7, so equal scores retain the first candidate encountered.


## Simulated Moves

CPU evaluation uses the normal `drop`, `won`, and `set_cell` board operations.

The position of a simulated piece is saved in registers `S` and `T`:

    S = simulated column
    T = simulated row

The `undo` routine clears that cell after the simulation.

This ensures that candidate evaluation leaves the real game board unchanged.


## Register Use

Named registers are used as follows:

    A   column
    B   player / cell value
    C   player input
    D   row
    E   decimal column place

    F   current CPU score
    G   best CPU score
    H   best CPU column

    I   indirect board row
    J   display loop
    K   cell value

    L   win row loop
    M   win column loop
    N   win row step
    O   win column step
    P   four-cell counter

    Q   CPU column loop
    R   scratch

    S   simulated column
    T   simulated row

Flags:

    Flag 0   win detected
    Flag 10  equation/message display


## Development

The game logic was first implemented as a Perl reference model.

The files in this example are:

- `C.asm`: HP-35s assembly source.
- `C.35s`: calculator program listing generated from the assembly source.
- `prototype.pl`: Perl reference model, including its rule and CPU-strategy tests.

The prototype was used to exercise:

- decimal board encoding,
- cell access,
- piece placement,
- horizontal wins,
- vertical wins,
- both diagonal win directions,
- non-winning positions,
- full-board positions without a winner,
- immediate CPU wins,
- immediate player-win blocking,
- CPU preference for the center column.

The HP-35s implementation intentionally remains close to that model while replacing Perl data structures and control flow with calculator registers, flags, `ISG`/`DSE`, `XEQ`, and `GTO`.


## Design Goals

The implementation favors simple and explicit HP-35s 
