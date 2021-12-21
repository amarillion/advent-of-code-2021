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


auto solve (string fname) {
	string[] lines = readLines(fname);
	
	int[] pos = lines.map!(l => to!int(l[$-1..$])).array;
	int[] score = [ 0, 0 ];

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
			writefln("Player %s rolls %s and moves to space %s for a total score of %s", p, advance, pos[p], score[p]);
			if (score[p] >= 1000) { done = true; break; }
		}
	}
	

	int loserScore = min(score[0], score[1]);
	writefln("%s %s", totalRolls, loserScore);
	return [ totalRolls * loserScore ];
}

void main() {
	assert (solve("test") == [ 739785 ]);
	writeln (solve("input"));
}
