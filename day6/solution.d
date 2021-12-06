#!/usr/bin/env -S rdmd -I..

import common.io;
import common.sparsegrid;
import common.vec;
import std.stdio;
import std.conv;
import std.algorithm;
import std.array;
import std.concurrency;

alias State = ulong[int];

State simulateDay(const State state) {
	ulong[int] result;

	if (0 in state) {
		result[6] += state[0];
		result[8] += state[0];
	}
	for (int i = 1; i <= 8; ++i) {
		if (i in state) {
			result[i-1] += state[i];
		}
	}
	return result;
}

ulong simulate(const int[] initialState, int days) {
	State state;
	foreach(fish; initialState) {
		state[fish]++;
	}
	writeln(state);

	for (int i = 0; i < days; ++i) {
		state = simulateDay(state);
		writefln("After %s days: %s", i+1, state.values.sum);
		writeln(state.values);
	}

	return state.values.sum;
}

auto solve (string fname) {
	string line = readLines(fname)[0];
	int[] state = line.split(",").map!(to!int).array;


	return [
		simulate(state, 80),
		simulate(state, 256)
	];
}

void main() {
	assert (solve("test") == [ 5934, 26_984_457_539 ]);
	writeln (solve("input"));
}
