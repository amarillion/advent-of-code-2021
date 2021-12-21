#!/usr/bin/env -S rdmd -I..

import common.io;
import common.vec;
import std.stdio;
import std.conv;
import std.algorithm;
import std.array;
import std.concurrency;
import std.math;
import std.range;
import std.uni;
import common.util;
import common.grid;
import common.coordrange;

ulong part1(const int[] initialPos) {
	int[] score = [ 0, 0 ];
	int[] pos = initialPos.dup;

	int die = 0;
	int totalRolls = 0;
	int roll() {
		die = (die % 100) + 1;
		totalRolls++;
		return die;
	}

	bool done = false;
	while(!done) {
		for (int p = 0; p < 2; ++p) {
			int advance = roll() + roll() + roll();
			pos[p] += advance;
			while(pos[p] > 10) pos[p] -= 10;
			score[p] += pos[p];
			// writefln("Player %s rolls %s and moves to space %s for a total score of %s", p, advance, pos[p], score[p]);
			if (score[p] >= 1000) { done = true; break; }
		}
	}
	
	int loserScore = min(score[0], score[1]);
	// writefln("%s %s", totalRolls, loserScore);
	return totalRolls * loserScore;
}

struct State {
	int[2] score;
	int[2] pos;
}

ulong part2(const int[] initialPos) {
	ulong[State] states;

	State initialState;
	initialState.score = [0, 0];
	initialState.pos = [initialPos[0], initialPos[1]];
	states[initialState] = 1;

	State advanceState(const State input, int p, int[3] roll) {
		State result = input;
		int advance = roll[0] + roll[1] + roll[2];
		result.pos[p] += advance;
		while(result.pos[p] > 10) result.pos[p] -= 10;
		result.score[p] += result.pos[p];
		return result;
	}

	bool done = false;
	ulong[int] wonCount;

	while(!done) {
		for (int p = 0; p < 2; ++p) {
			writeln(states);
			ulong[State] newStates;
			foreach (k, v; states) {
				for (int r1 = 1; r1 <= 3; ++r1) {
					for (int r2 = 1; r2 <= 3; ++r2) {
						for (int r3 = 1; r3 <= 3; ++r3) {
							State newState = advanceState(k, p, [r1, r2, r3]);
							if (newState.score[p] >= 21) {
								wonCount[p] += v;
							}
							else {
								newStates[newState] += v;
							}
						}
					}
				}
			}
			states = newStates;
			writeln(states);
		}
		if (states.length == 0) {
			break;
		}
	}

	writeln(wonCount);
	return max(wonCount[0], wonCount[1]);
}

auto solve (string fname) {
	string[] lines = readLines(fname);
	int[] pos = lines.map!(l => to!int(l[$-1..$])).array;

	return [ part1(pos), part2(pos) ];
}

void main() {
	assert (solve("test") == [ 739785, 444_356_092_776_315 ]);
	writeln (solve("input"));
}
