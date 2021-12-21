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

struct State {
	int[2] score = [0, 0];
	int[2] pos;
}

State advanceState(const State input, int p, int advance) {
	State result = input;
	result.pos[p] += advance;
	while(result.pos[p] > 10) result.pos[p] -= 10;
	result.score[p] += result.pos[p];
	// writefln("Player %s rolls %s and moves to space %s for a total score of %s", p, advance, result.pos[p], result.score[p]);
	return result;
}

ulong part1(State initialState) {
	State state = initialState; 

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
			state = advanceState(state, p, roll() + roll() + roll());
			if (state.score[p] >= 1000) { done = true; break; }
		}
	}
	
	int loserScore = min(state.score[0], state.score[1]);
	return totalRolls * loserScore;
}

auto generateDiracTriples() {
	int[int] result;
	for (int r1 = 1; r1 <= 3; ++r1) {
		for (int r2 = 1; r2 <= 3; ++r2) {
			for (int r3 = 1; r3 <= 3; ++r3) {
				int roll = r1 + r2 + r3;
				result[roll]++;
			}
		}
	}
	return result;
}
enum diracFrq = generateDiracTriples();

ulong part2(State initialState) {
	ulong[State] states;
	states[initialState] = 1;
	ulong[int] wonCount;

	do {
		for (int p = 0; p < 2; ++p) {
			ulong[State] newStates;
			foreach (state, stateCount; states) {
				foreach(rollSum, rollFrq; diracFrq) {
					State newState = advanceState(state, p, rollSum);
					if (newState.score[p] >= 21) {
						wonCount[p] += (stateCount * rollFrq);
					}
					else {
						newStates[newState] += (stateCount * rollFrq);
					}
				}
			}
			states = newStates;
		}
	} while(states.length > 0);

	return max(wonCount[0], wonCount[1]);
}

auto solve (string fname) {
	string[] lines = readLines(fname);
	int[2] pos = lines.map!(l => to!int(l[$-1..$])).array;
	State initialState;
	initialState.pos = pos;

	return [ part1(initialState), part2(initialState) ];
}

void main() {
	assert (solve("test") == [ 739785, 444_356_092_776_315 ]);
	writeln (solve("input"));
}
