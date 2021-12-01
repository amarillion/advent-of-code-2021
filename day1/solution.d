#!/usr/bin/env -S rdmd -unittest -I..

import common.io;
import std.stdio;
import std.string;
import std.conv;
import std.algorithm;
import std.array;

int countIncreases(const int[] data) {
	int result = 0;
	int prev = data[0];
	foreach(int i; data[1..$]) {
		if (i > prev) { result++; }
		prev = i;
	}
	return result;
}

int[] slidingWindow(const int[] data) {
	int[] result = [];
	for (int i = 1; i + 1 < data.length; ++i) {
		result ~= data[i-1] + data[i] + data[i+1];
	}
	return result;
}

void main() {
	int[] data = readLines("input").map!(to!int).array;

	writeln(countIncreases(data));
	writeln(countIncreases(slidingWindow(data)));
}

unittest {
	const testData = [ 199, 200, 208, 210, 200, 207, 240, 269, 260, 263 ];
	assert(countIncreases(testData) == 7);
	assert(slidingWindow(testData) == [ 607, 618, 618, 617, 647, 716, 769, 792 ]);
	assert(countIncreases(slidingWindow(testData)) == 5);
}