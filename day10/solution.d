#!/usr/bin/env -S rdmd -I..

import common.io;
import std.stdio;
import std.conv;
import std.algorithm;
import std.array;
import std.concurrency;
import std.math;

struct ParseResult {
	bool error;
	dchar unexpected;
	dchar[] stack;
}

ParseResult parseLine(string input) {
	dchar[] stack;
	dchar[] line = to!(dchar[])(input);

	bool expect(dchar ch) {
		if (stack.back == ch) {
			stack.popBack();
			return true;
		}
		return false;
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
				if (!expect(ch)) return ParseResult(true, ch, stack); 
				break;
			default: assert(0);
		}
	}

	// ok!
	return ParseResult(false, '\0', stack);
}

int part1(ParseResult result) {
	int[dchar] scores = [
		')': 3,
		']': 57,
		'}': 1197,
		'>': 25137
	];
	return scores[result.unexpected];
}

ulong part2(ParseResult data) {
	int[dchar] scores = [
		')': 1,
		']': 2,
		'}': 3,
		'>': 4
	];
	ulong result = 0;
	while(!data.stack.empty) {
		result *= 5;
		result += scores[data.stack.back];
		data.stack.popBack;
	}
	return result;
}

auto solve (string fname) {
	string[] lines = readLines(fname);

	int count = 0;
	ulong[] scores = [];
	foreach(line; lines) {
		auto result = parseLine(line);
		if (result.error) {
			count += part1(result);	
		}
		else {
			scores ~= part2(result);
		}
	}

	sort (scores);

	return [
		count,
		scores[scores.length / 2]
	];
}

void main() {
	// too low: 462448347
	assert (solve("test") == [ 26397, 288957 ]);
	writeln (solve("input"));
}
