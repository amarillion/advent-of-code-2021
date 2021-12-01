#!/usr/bin/env -S rdmd -unittest -I..
module day1.alt;

import common.io;
import std.stdio;
import std.string;
import std.conv;
import std.algorithm;
import std.array;

/**
	Pass a sliding window over T[] with window size N.

	Examples:
	SlidingWindow!(2, int)[1, 2, 3] becomes [[1, 2], [2, 3]]
	SlidingWindow!(3, int)[1, 2, 3, 4, 5] becomes [[1, 2, 3], [2, 3, 4], [3, 4, 5]]
*/
struct SlidingWindow(int N, T) {
	const T[] parent;
	int pos;

	this(const T[] parent) {
		this.parent = parent;
		pos = N;
	}

	const(T)[] front() {
		return parent[pos-N..pos];
	}

	void popFront() {
		pos++;
	}

	bool empty() const {
		return pos >= parent.length + 1;
	}
}

size_t countIncreases(const int[] data) {
	return SlidingWindow!(2, int)(data).count!(a => a[1] > a[0]);
}

int[] sumThrees(const int[] data) {
	return SlidingWindow!(3, int)(data).map!(sum).array;
}

void main() {
	int[] data = readLines("input").map!(to!int).array;

	writeln(countIncreases(data));
	writeln(countIncreases(sumThrees(data)));
}

unittest {
	const testData = [ 199, 200, 208, 210, 200, 207, 240, 269, 260, 263 ];
	assert(countIncreases(testData) == 7);
	assert(sumThrees(testData) == [ 607, 618, 618, 617, 647, 716, 769, 792 ]);
	assert(countIncreases(sumThrees(testData)) == 5);
}