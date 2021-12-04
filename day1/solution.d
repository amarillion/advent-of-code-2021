#!/usr/bin/env -S rdmd -I..
module day1.alt;

import common.io;
import std.stdio;
import std.string;
import std.conv;
import std.algorithm;
import std.array;
import std.range;

size_t countIncreases(const int[] data) {
	return data.slide(2).count!(a => a[1] > a[0]);
}

int[] sumThrees(const int[] data) {
	return data.slide(3).map!(sum).array;
}

auto solve(string fname) {
	int[] data = readLines(fname).map!(to!int).array;
	
	return [
		countIncreases(data),
		countIncreases(sumThrees(data))
	];
}

void main() {
	assert(solve("test") == [ 7, 5 ]);
	writeln(solve("input"));
}
