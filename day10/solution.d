#!/usr/bin/env -S rdmd -I..

import common.io;
import std.stdio;
import std.conv;
import std.algorithm;
import std.array;
import std.concurrency;
import std.math;


int parseLine(string input) {
	dchar[] stack;
	dchar[] line = to!(dchar[])(input);

	int[dchar] scores = [
		')': 3,
		']': 57,
		'}': 1197,
		'>': 25137
	];

	int expect(dchar ch) {
		if (stack.back == ch) {
			stack.popBack();
			return 0;
		}
		else {
			return scores[ch];
		}
	}

	while (!line.empty) {
		dchar ch = line[0];
		line.popFront;
		switch(ch) {
			case '{': stack ~= '}'; break;
			case '<': stack ~= '>'; break;
			case '[': stack ~= ']'; break;
			case '(': stack ~= ')'; break;
			case '}': case '>': case ')': case ']': 
				int result = expect(ch);
				if (result != 0) return result; 
				break;
			default: assert(0);
		}
	}

	// ok!
	return 0;
}

auto solve (string fname) {
	string[] lines = readLines(fname);

	int count = 0;

	foreach(line; lines) {
		writeln(line, " ", parseLine(line));
		count += parseLine(line);
	}
	return [
		count
	];
}

void main() {
	assert (solve("test") == [ 26397 ]);
	writeln (solve("input"));
}
