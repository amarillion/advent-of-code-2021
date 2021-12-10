#!/usr/bin/env -S rdmd -I..

import common.io;
import std.stdio;
import std.conv;
import std.algorithm;
import std.range;

struct ParseResult {
	bool error;
	dchar unexpected;
	dchar[] stack;

	static ParseResult ok(dchar[] stack) { return ParseResult(false, '\0', stack); }
	static ParseResult foundUnexpected(dchar unexpected) { return ParseResult(true, unexpected, []); }
}

dchar[] OPEN_PARENS = ['[', '(', '<', '{'];
dchar[] CLOSE_PARENS = [']', ')', '>', '}'];
enum dchar[dchar] MATCHING_PAREN = ['[': ']', '(': ')', '<': '>', '{': '}'];

ParseResult parseLine(string input) {
	dchar[] stack;
	dchar[] line = to!(dchar[])(input);

	while (!line.empty) {
		dchar ch = line[0];
		line.popFront;

		if (OPEN_PARENS.canFind(ch)) {
			stack ~= MATCHING_PAREN[ch];
		}
		else {
			if (stack.back == ch) {
				stack.popBack();
			}
			else {
				return ParseResult.foundUnexpected(ch);
			}
		}
	}

	return ParseResult.ok(stack);
}

int scoreUnexpectedChar(ParseResult result) {
	int[dchar] scores = [
		')': 3,
		']': 57,
		'}': 1197,
		'>': 25137
	];
	return scores[result.unexpected];
}

ulong scoreRemainingStack(ParseResult data) {
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
			count += scoreUnexpectedChar(result);
		}
		else {
			scores ~= scoreRemainingStack(result);
		}
	}
	sort (scores);

	return [
		count,
		scores[scores.length / 2]
	];
}

void main() {
	assert (solve("test") == [ 26397, 288957 ]);
	writeln (solve("input"));
}
