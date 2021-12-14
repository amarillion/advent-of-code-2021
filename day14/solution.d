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
import common.sparsegrid;

int[string] applyRules(int[string] pairCounts, string[string] rules) {
	int[string] result;
	foreach(k, v; pairCounts) {
		string toInsert = rules[k];
		string left = k[0] ~ toInsert;
		string right = toInsert ~ k[1];
		result[left] += v;
		result[right] += v; 
	}
	return result;
}

auto solve (string fname) {
	string[] lines = readLines(fname);
	string init = lines[0];

	string[string] rules;
	foreach(rule; lines[2..$].map!(s => s.split(" -> "))) {
		rules[rule[0]] = rule[1];
	}
	
	int[string] pairCounts;
	foreach(pair; init.slide(2)) {
		pairCounts[to!string(pair)]++;
	}

	writeln(pairCounts);
	for (int i = 0; i < 10; ++i) {
		pairCounts = applyRules(pairCounts, rules);
	}
	writeln(pairCounts);

	// now get elemental quantities.
	int[char] elementCounts;
	foreach(k, v; pairCounts) {
		char element = k[0];
		// only count left half.
		elementCounts[element] += v;
	}
	elementCounts[init[$-1]] += 1;

	int[] elementValues = elementCounts.values;
	sort(elementValues);
	writeln(elementValues);

	return [
		elementValues[$-1] - elementValues[0]
	];
}

void main() {
	assert (solve("test") == [ 1588 ]);
	writeln (solve("input"));
}
