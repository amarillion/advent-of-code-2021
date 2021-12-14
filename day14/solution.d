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

alias PairCounts = ulong[string];

PairCounts applyRules(PairCounts pairCounts, string[string] rules) {
	PairCounts result;
	foreach(k, v; pairCounts) {
		string left = k[0] ~ rules[k];
		string right = rules[k] ~ k[1];
		result[left] += v;
		result[right] += v; 
	}
	return result;
}

ulong score(PairCounts pairCounts, string init) {
	ulong[char] elementCounts;
	foreach(k, v; pairCounts) {
		char element = k[0];
		// only count left half of each pair
		elementCounts[element] += v;
	}
	// the only thing we're missing is the closing pair
	elementCounts[init[$-1]] += 1;

	ulong[] elementValues = elementCounts.values;
	sort(elementValues);
	return elementValues[$-1] - elementValues[0];
}

auto solve (string fname) {
	string[] lines = readLines(fname);
	string init = lines[0];

	string[string] rules;
	foreach(rule; lines[2..$].map!(s => s.split(" -> "))) {
		rules[rule[0]] = rule[1];
	}
	
	PairCounts pairCounts;
	foreach(pair; init.slide(2)) {
		pairCounts[to!string(pair)]++;
	}

	int i = 0;
	for (; i < 10; ++i) {
		pairCounts = applyRules(pairCounts, rules);
	}
	ulong part1 = score(pairCounts, init);

	for (; i < 40; ++i) {
		pairCounts = applyRules(pairCounts, rules);
	}
	ulong part2 = score(pairCounts, init);
	
	return [ part1, part2 ];
}

void main() {
	assert (solve("test") == [ 1588, 2_188_189_693_529 ]);
	writeln (solve("input"));
}
