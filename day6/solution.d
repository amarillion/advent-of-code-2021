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
	foreach(key, value; state) {
		if (key == 0) {
			result[6] += value;
			result[8] += value;
		}
		else {
			result[key - 1] += value;
		}
	}
	return result;
}

ulong simulate(const int[] initialState, int days) {
	State state;
	foreach(fish; initialState) {
		state[fish]++;
	}

	for (int i = 0; i < days; ++i) {
		state = simulateDay(state);
	}
	return state.values.sum;
}

auto solve (string fname) {
	string line = readLines(fname)[0];
	int[] initialState = line.split(",").map!(to!int).array;

	return [
		simulate(initialState, 80),
		simulate(initialState, 256)
	];
}

void main() {
	assert (solve("test") == [ 5934, 26_984_457_539 ]);
	writeln (solve("input"));
}
