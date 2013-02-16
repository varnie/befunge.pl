#!/usr/bin/perl

# $Id$

use strict;
use warnings;
use 5.010;
use bigint;

use English qw(-no_match_vars);
use Carp qw(croak);
use File::Basename 'basename';    #for getting basename of the program path
use Data::Dumper;

our $MAX_LINE_COUNT        ;
our $MAX_LINE_LENGTH       ;

our $NO_OPERATION          ;
our $PLUS                  ;
our $MINUS                 ;
our $MULTIPLY              ;
our $INT_DIVISION          ;
our $MOD_DIVISION          ;
our $NOT                   ;
our $MOVE_RIGHT            ;
our $MOVE_LEFT             ;
our $MOVE_UP               ;
our $MOVE_DOWN             ;
our $RAND                  ;
our $MOVE_RIGHT_OR_LEFT    ;
our $MOVE_DOWN_OR_UP       ;
our $STRING_MODE           ;
our $DUPLICATE_VALUE       ;
our $SWAP_VALUES           ;
our $POP                   ;
our $POP_AND_OUTPUT_INTEGER;
our $POP_AND_ASCII_OUTPUT  ;
our $TRAMPOLINE            ;
our $PUT_CALL              ;
our $GET_CALL              ;
our $USER_INPUT_INTEGER    ;
our $USER_INPUT_CHARACTER  ;
our $PROGRAM_END           ;
our $DIGIT_0               ;
our $DIGIT_1               ;
our $DIGIT_2               ;
our $DIGIT_3               ;
our $DIGIT_4               ;
our $DIGIT_5               ;
our $DIGIT_6               ;
our $DIGIT_7               ;
our $DIGIT_8               ;
our $DIGIT_9               ;
our $GREATER_THAN          ;

#use constant {
    *MAX_LINE_COUNT         = \80,
    *MAX_LINE_LENGTH        = \25,

    *NO_OPERATION           = \32,
    *PLUS                   = \43,
    *MINUS                  = \45,
    *MULTIPLY               = \42,
    *INT_DIVISION           = \47,
    *MOD_DIVISION           = \37,
    *NOT                    = \33,
    *MOVE_RIGHT             = \62,
    *MOVE_LEFT              = \60,
    *MOVE_UP                = \94,
    *MOVE_DOWN              = \118,
    *RAND                   = \63,
    *MOVE_RIGHT_OR_LEFT     = \95,
    *MOVE_DOWN_OR_UP        = \124,
    *STRING_MODE            = \34,
    *DUPLICATE_VALUE        = \58,
    *SWAP_VALUES            = \92,
    *POP                    = \36,
    *POP_AND_OUTPUT_INTEGER = \46,
    *POP_AND_ASCII_OUTPUT   = \44,
    *TRAMPOLINE             = \35,
    *PUT_CALL               = \112,
    *GET_CALL               = \103,
    *USER_INPUT_INTEGER     = \38,
    *USER_INPUT_CHARACTER   = \126,
    *PROGRAM_END            = \64,
    *DIGIT_0                = \48,
    *DIGIT_1                = \49,
    *DIGIT_2                = \50,
    *DIGIT_3                = \51,
    *DIGIT_4                = \52,
    *DIGIT_5                = \53,
    *DIGIT_6                = \54,
    *DIGIT_7                = \55,
    *DIGIT_8                = \56,
    *DIGIT_9                = \57,
    *GREATER_THAN           = \96;
#};

our $VERSION = 1;

use bigint;

if (@ARGV != 1) {
    croak "usage: @{[basename($PROGRAM_NAME)]} program.bf";
}

my $filename = $ARGV[0];
open my $fh, '<', $filename
  or croak "failed to open source file $filename: $OS_ERROR";

my @code;
my $code_lines;

#parsing
while (my $line = <$fh>) {
    chomp $line;
    my @chars = split //, substr $line, 0, $MAX_LINE_LENGTH;

    foreach my $ch (@chars) {
        push @code, get_instr($ch);
    }

    if (@chars < $MAX_LINE_LENGTH) {
        push @code, ($NO_OPERATION) x ($MAX_LINE_LENGTH - @chars);
    }

    $code_lines++;
    last if $INPUT_LINE_NUMBER > $MAX_LINE_COUNT - 1;
}

close $fh;

#say Dumper(@code);
#exit 0;
$OUTPUT_AUTOFLUSH = 1;

#interpret it, luke!
my @stack;
my ($x, $y, $stack_length, $direction, $string_mode) = (0, 0, 0, $MOVE_RIGHT, 0);

while (1) {

    my $op = $code[ $y * $MAX_LINE_LENGTH + $x ];

    if ($op == $STRING_MODE) {
        $string_mode = !$string_mode;
    } else {
        if ($string_mode) {
            push @stack, $op;
            ++$stack_length;
        } else {

            #blabla
            if ($op == $NO_OPERATION) {
                #do nothing
            } elsif ($op >= $DIGIT_0 && $op <= $DIGIT_9) {
                push @stack, $op - $DIGIT_0;
                ++$stack_length;
            } elsif ($op == $PLUS) {
                if ($stack_length > 1) {
                    my $v2 = pop @stack;
                    --$stack_length;
                    $stack[-1] += $v2;
                }
            } elsif ($op == $MINUS) {
                if ($stack_length > 0) {
                    my $v2 = pop @stack;
                    if (--$stack_length > 0) {
                        $stack[-1] -= $v2;
                    } else {
                        push @stack, -$v2;
                    }
                }
            } elsif ($op == $MULTIPLY) {
                if ($stack_length > 0) {
                    my $v2 = pop @stack;
                    if (--$stack_length > 0) {
                        $stack[-1] *= $v2;
                    } else {
                        push @stack, 0;
                    }
                }
            } elsif ($op == $INT_DIVISION) {
                if ($stack_length > 0) {
                    my $v2 = pop @stack;
                    if (--$stack_length > 0) {
                        $stack[-1] = int($stack[-1] / $v2);
                    } else {
                        push @stack, 0;
                    }
                }
            } elsif ($op == $MOD_DIVISION) {
                if ($stack_length > 0) {
                    my $v2 = pop @stack;
                    if (--$stack_length > 0) {
                        $stack[-1] %= $v2;
                    } else {
                        push @stack, 0;
                    }
                }
            } elsif ($op == $NOT) {
                if ($stack_length > 0) {
                    $stack[-1] = $stack[-1] > 0 ? 1 : 0;
                }
            } elsif ($op == $MOVE_RIGHT) {
                $direction = $MOVE_RIGHT;
            } elsif ($op == $MOVE_LEFT) {
                $direction = $MOVE_LEFT;
            } elsif ($op == $MOVE_UP) {
                $direction = $MOVE_UP;
            } elsif ($op == $MOVE_DOWN) {
                $direction = $MOVE_DOWN;
            } elsif ($op == $RAND) {
                my $rand_value = int rand 4;
                if ($rand_value == 0) {
                    $direction = $MOVE_LEFT;
                } elsif ($rand_value == 1) {
                    $direction = $MOVE_RIGHT;
                } elsif ($rand_value == 2) {
                    $direction = $MOVE_UP;
                } else {
                    $direction = $MOVE_DOWN;
                }
            } elsif ($op == $MOVE_RIGHT_OR_LEFT) {
                if ($stack_length > 0) {
                    my $v1 = pop @stack;
                    --$stack_length;
                    $direction = $v1 == 0 ? $MOVE_RIGHT : $MOVE_LEFT;
                } else {
                    $direction = $MOVE_RIGHT;
                }
            } elsif ($op == $MOVE_DOWN_OR_UP) {
                if ($stack_length > 0) {
                    my $v1 = pop @stack;
                    --$stack_length;
                    $direction = $v1 == 0 ? $MOVE_DOWN : $MOVE_UP;
                } else {
                    $direction = $$MOVE_DOWN;
                }
            } elsif ($op == $POP_AND_OUTPUT_INTEGER) {
                if ($stack_length > 0) {
                    print pop @stack;
                    --$stack_length;
                } else {
                    print 0;
                }
            } elsif ($op == $TRAMPOLINE) {
                if ($direction == $MOVE_RIGHT) {
                    if (++$x >= $MAX_LINE_LENGTH) {
                        $x = 0;
                    }
                } elsif ($direction == $MOVE_LEFT) {
                    if (--$x < 0) {
                        $x = $MAX_LINE_LENGTH- 1;
                    }
                } elsif ($direction == $MOVE_UP) {
                    if (--$y < 0) {
                        $y = $code_lines - 1;
                    }
                } else {
                    if (++$y > $code_lines) {
                        $y = 0;
                    }
                }
            } elsif ($op == $DUPLICATE_VALUE) {
                if ($stack_length > 0) {
                    push @stack, $stack[-1];
                } else {
                    push @stack, 0;
                }
                ++$stack_length;
            } elsif ($op == $SWAP_VALUES) {
                if ($stack_length > 1) {
                    @stack[ -2, -1 ] = @stack[ -1, -2 ];
                } else {
                    push @stack, 0;
                    ++$stack_length;
                }
            } elsif ($op == $GREATER_THAN) {
                if ($stack_length > 1) {
                    my $v2 = pop @stack;
                    --$stack_length;
                    $stack[-1] = $stack[-1] > $v2 ? 1 : 0;
                } elsif ($stack_length == 1) {
                    $stack[-1] = 0;
                } else {
                    push @stack, 0;
                    ++$stack_length;
                }
            } elsif ($op == $MOVE_RIGHT_OR_LEFT) {
                if ($stack_length > 0) {
                    my $v1 = pop @stack;
                    --$stack_length;
                    $direction = $v1 == 0 ? $MOVE_RIGHT : $MOVE_LEFT;
                } else {
                    $direction = $MOVE_RIGHT;
                }
            } elsif ($op == $MOVE_DOWN_OR_UP) {
                if ($stack_length > 0) {
                    my $v1 = pop @stack;
                    --$stack_length;
                    $direction = $v1 == 0 ? $MOVE_DOWN : $MOVE_UP;
                } else {
                    $direction = $MOVE_DOWN;
                }
            } elsif ($op == $POP) {
                if ($stack_length > 0) {
                    pop @stack;
                    --$stack_length;
                }
            } elsif ($op == $POP_AND_ASCII_OUTPUT) {
                if ($stack_length > 0) {
                    print chr pop @stack;
                    --$stack_length;
                } else {
                    print 0;
                }
            } elsif ($op == $USER_INPUT_INTEGER) {
                print 'enter integer: ';
                if (defined(my $input = readline(STDIN))) {
                    chomp $input;
                    if ($input =~ /^\d+$/) {
                        push @stack, $input;
                    } else {
                        push @stack, 0;
                    }
                } else {
                    push @stack, 0;
                }
                ++$stack_length;
            } elsif ($op == $USER_INPUT_CHARACTER) {
                print 'enter character: ';
                if (defined(my $input = readline(STDIN))) {
                    chomp $input;
                    push @stack, ord substr($input, 0, 1);
                } else {
                    push @stack, ord '0';
                }
                ++$stack_length;
            } elsif ($op == $PUT_CALL) {
		my ($y, $x, $v);
	        if ($stack_length > 2) {
		    ($y, $x, $v) = (pop @stack, pop @stack, pop @stack);
		    $stack_length -= 3;
	        } elsif ($stack_length == 2) {
		    ($y, $x, $v) = (pop @stack, pop @stack, ord 0);
		    $stack_length = 0;
		} elsif ($stack_length == 1) {
		    ($y, $x, $v) = (pop @stack, 0, ord 0);
		    $stack_length = 0;
		} else {
	            ($y, $x, $v) = (0, 0, chr ord 0);
		    $stack_length = 0;
		}
		if ($x > $MAX_LINE_LENGTH - 1 || $y > $MAX_LINE_COUNT - 1) {
		    croak 'wrong coordinates!';
                } else {
		    $code[ $y * $MAX_LINE_LENGTH + $x ] = get_instr(chr $v);
                }
            } elsif ($op == $GET_CALL) {
		my ($y, $x);
	        if ($stack_length > 1) {
		    ($y, $x) = (pop @stack, pop @stack);
		    --$stack_length;
	        } elsif ($stack_length == 1) {
		    ($y, $x) = (pop @stack, 0);
		} else {
	            ($y, $x) = (0, 0);
		    ++$stack_length;
		}
		if ($x > $MAX_LINE_LENGTH - 1 || $y > $MAX_LINE_COUNT - 1) {
		    croak 'wrong coordinates!';
                } else {
		    push @stack, chr $code[ $y * $MAX_LINE_LENGTH + $x ];
                }
             } elsif ($op == $PROGRAM_END) {
                last;
            }
            #blabla
        }
    }

    #advance the position
    if ($direction == $MOVE_RIGHT) {
        if (++$x >= $MAX_LINE_LENGTH - 1) {
            $x = 0;
        }
    } elsif ($direction == $MOVE_LEFT) {
        if (--$x < 0) {
            $x = $MAX_LINE_LENGTH - 1;
        }
    } elsif ($direction == $MOVE_UP) {
        if (--$y < 0) {
            $y = $code_lines - 1;
        }
    } else {
        if (++$y >= $code_lines) {
            $y = 0;
        }
    }
}

say "\ngood bye";

sub get_instr {
    my $ch = shift;
    return do {
        if ($ch =~ /\s/) {
            $NO_OPERATION;
        } elsif ($ch eq q{`}) {
            $GREATER_THAN;
        } elsif ($ch eq q{+}) {
            $PLUS;
        } elsif ($ch eq q{-}) {
            $MINUS;
        } elsif ($ch eq q{*}) {
            $MULTIPLY;
        } elsif ($ch eq q{/}) {
            $INT_DIVISION;
        } elsif ($ch eq q{%}) {
            $MOD_DIVISION;
        } elsif ($ch eq q{!}) {
            $NOT;
        } elsif ($ch eq q{>}) {
            $MOVE_RIGHT;
        } elsif ($ch eq q{<}) {
            $MOVE_LEFT;
        } elsif ($ch eq q{^}) {
            $MOVE_UP;
        } elsif ($ch eq q{v}) {
            $MOVE_DOWN;
        } elsif ($ch eq q{?}) {
            $RAND;
        } elsif ($ch eq q{_}) {
            $MOVE_RIGHT_OR_LEFT;
        } elsif ($ch eq q{|}) {
            $MOVE_DOWN_OR_UP;
        } elsif ($ch eq q{"}) {
            $STRING_MODE;
        } elsif ($ch eq q{:}) {
            $DUPLICATE_VALUE;
        } elsif ($ch eq q{\\}) {
            $SWAP_VALUES;
        } elsif ($ch eq q{$}) {
            $POP;
        } elsif ($ch eq q{.}) {
            $POP_AND_OUTPUT_INTEGER;
        } elsif ($ch eq q{,}) {
            $POP_AND_ASCII_OUTPUT;
        } elsif ($ch eq q{#}) {
            $TRAMPOLINE;
        } elsif ($ch eq q{p}) {
            $PUT_CALL;
        } elsif ($ch eq q{g}) {
            $GET_CALL;
        } elsif ($ch eq q{&}) {
            $USER_INPUT_INTEGER;
        } elsif ($ch eq q{~}) {
            $USER_INPUT_CHARACTER;
        } elsif ($ch eq q{@}) {
            $PROGRAM_END;
        } else {
            ord $ch;
        }
    }
}
