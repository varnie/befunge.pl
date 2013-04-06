#!/usr/bin/perl

# $Id$

use strict;
use warnings;
use 5.010;

use English qw(-no_match_vars);
use Carp qw(croak);
use File::Basename qw(basename);    #for getting basename of the program path

our $VERSION = 1;

our $MAX_LINE_COUNT;
our $MAX_LINE_LENGTH;
our $NO_OPERATION;
our $MOVE_RIGHT;
our $MOVE_LEFT;
our $MOVE_UP;
our $MOVE_DOWN;

*MAX_LINE_COUNT = \80,
*MAX_LINE_LENGTH = \25;
*NO_OPERATION = \-1;
*MOVE_RIGHT = \-1;
*MOVE_LEFT = \-2;
*MOVE_UP = \-3;
*MOVE_DOWN = \-4;

if (@ARGV != 1) {
    croak "usage: @{[basename($PROGRAM_NAME)]} program.bf";
}

my $filename = $ARGV[0];
open my $fh, '<', $filename or croak "failed to open source file $filename: $OS_ERROR";

my ($code_ref, $code_lines_cnt) = parse_file($fh);
my @code = @$code_ref;

$OUTPUT_AUTOFLUSH = 1;

#interpret it, luke!
my @stack;
my ($x, $y, $direction, $string_mode) = (0, 0, $MOVE_RIGHT, 0);

sub f_push {
    push @stack, shift;
}

sub f_pop {
    return @stack ? pop @stack : 0;
}

my %funcs = (
    '>' => sub { $direction = $MOVE_RIGHT},
    'v' => sub { $direction = $MOVE_DOWN},
    '<' => sub { $direction = $MOVE_LEFT},
    '^' => sub { $direction = $MOVE_UP},
    ',' => sub { print chr f_pop(); },
    '*' => sub { if (@stack) { f_push(f_pop() * f_pop());} },
    '/' => sub { if (@stack) { my ($v2, $v1) = (f_pop(), f_pop()); f_push($v2 > 0 ? int($v1/$v2) : 0);}},
    '%' => sub { if (@stack) { my ($v2, $v1) = (f_pop(), f_pop()); f_push($v1 % $v2);}},
    '+' => sub { if (@stack > 1) { my ($v2, $v1) = (f_pop(), f_pop()); f_push($v2 + $v1); } },
    '-' => sub { if (@stack) { my ($v2, $v1) = (f_pop(), f_pop()); f_push($v1 - $v2); } },
    '!' => sub { if (@stack) { my $v2 = f_pop(); f_push($v2 > 0 ? 1 : 0);} },
    '?' => sub { 
        my $rand_val = int rand 4; 
	if ($rand_val == 0) {
	    $direction = $MOVE_LEFT;
	} elsif ($rand_val == 1) {
	    $direction = $MOVE_RIGHT;
	} elsif ($rand_val == 2) {
	    $direction = $MOVE_UP;
	} else {
	    $direction = $MOVE_DOWN;
	} 
    },
    '_' => sub { $direction = f_pop() == 0 ? $MOVE_RIGHT : $MOVE_LEFT; },
    '|' => sub { $direction = f_pop() == 0 ? $MOVE_DOWN : $MOVE_UP; },
    '.' => sub { print f_pop(); },
    '#' => sub { 
	if ($direction == $MOVE_RIGHT) {
	    if (++$x >= $MAX_LINE_LENGTH) {
	        $x = 0;
	    }
	} elsif ($direction == $MOVE_LEFT) {
	    if (--$x < 0) {
                $x = $MAX_LINE_LENGTH - 1;
	    }
	} elsif ($direction == $MOVE_UP) {
	    if (--$y < 0) {
	        $y = $code_lines_cnt - 1
	    }
        } else {
	    if (++$y > $code_lines_cnt) {
	        $y = 0;
	    }
	}	
    },
    ':' => sub { f_push(@stack ? $stack[-1] : 0); },
    '\\' => sub { if (@stack > 1) { @stack[-2, -1] = @stack[-1, -2]; } else { f_push(0); } },
    '`' => sub { my ($v2, $v1) = (f_pop(), f_pop()); f_push($v1 > $v2 ? 1 : 0); },
    '$' => sub { f_pop(); },
    '&' => sub { 
        print 'enter integer: ';
        if (defined(my $input = readline(STDIN))) {
            chomp $input;        
      	    f_push(($input =~ /^\d+$/) ? $input : 0);
	} else {
	    f_push(0);
	}
    },                              
    '~' => sub { 
	print 'enter character: ';
    	if (defined(my $input = readline(STDIN))) {
	    chomp $input;
	    f_push(ord substr($input, 0, 1));
	} else {
	    f_push(ord '0');
	}
    },
    'p' => sub { 
        my ($y, $x, $v) = (f_pop(), f_pop(), f_pop());
	if ($x > $MAX_LINE_LENGTH - 1 || $y > $MAX_LINE_COUNT - 1) {
	    croak 'wrong coordinates!';
	} else {
	    $code[$y * $MAX_LINE_LENGTH + $x] = $v;
	}
    },
    'g' => sub { 
        my ($y, $x) = (f_pop(), f_pop());
	if ($x > $MAX_LINE_LENGTH - 1 || $y > $MAX_LINE_COUNT - 1) {
	    croak 'wrong coordinates!';
        } else {
	    f_push(chr $code[$y * $MAX_LINE_LENGTH + $x]);
	}
    },
    '@' => sub{ exit(0); }
);

while (1) {
    my $op = $code[ $y * $MAX_LINE_LENGTH + $x ];
    my $ch = chr $op;  
    if ($ch eq '"') {
        $string_mode = !$string_mode;
    } else {
        if ($string_mode) {
            f_push($op);
        } else {
            if ($op == $NO_OPERATION || $ch eq ' ') {
	        #do nothing
	    } elsif ($op >= ord '0' && $op <= ord '9') {
	        f_push($op - ord '0');
	    } else {
	    	$funcs{$ch}->();
	    }  
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
            $y = $code_lines_cnt - 1;
        }
    } else {
        if (++$y >= $code_lines_cnt) {
            $y = 0;
        }
    }
}

sub parse_file {
    my $fh = shift;
    my (@code, $code_lines_cnt);

    while (my $line = <$fh>) {
        chomp $line;
        my @chars = split //, substr $line, 0, $MAX_LINE_LENGTH;
    
	push @code, map {ord} @chars;
    
        if (@chars < $MAX_LINE_LENGTH) {
            push @code, ($NO_OPERATION) x ($MAX_LINE_LENGTH - @chars);
        }
    
        ++$code_lines_cnt;
        last if $INPUT_LINE_NUMBER > $MAX_LINE_COUNT - 1;
    }

    return (\@code, $code_lines_cnt);
}  
