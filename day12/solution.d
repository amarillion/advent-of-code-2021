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

alias Edge = string[];
alias Path = string[];
alias Node = string;

const(Path)[] getPaths(const Node[] path, const Node[][Node] adjacent, in Node[] exclude, bool canRevisit) {
	string node = path.back;
	if (node == "end") { return [ path ]; }
	
	const (Path)[] result = [];
	bool isSmallCave(string n) { return n.toLower() == n; }

	const(Node)[] excludeNext = exclude;

	if (isSmallCave(node)) {
		if (!canRevisit) {
			excludeNext ~= node;
		}
		else {
			auto visited = path[0..$-1];
			if (visited.canFind(node)) {
				excludeNext ~= visited.filter!isSmallCave.array;
				canRevisit = false;
			}
		}
	}

	foreach(dest; adjacent[node]) {
		if (excludeNext.canFind(dest)) continue;
		result ~= getPaths(path ~ dest, adjacent, excludeNext, canRevisit);
	}
	return result;
}

auto solve (string fname) {
	Node[][Node] adjacent;
	foreach(Edge e; readLines(fname).map!(s => s.split("-"))) {
		adjacent[e[0]] ~= e[1];
		adjacent[e[1]] ~= e[0];
	}
	
	return [
		getPaths([ "start" ], adjacent, [ "start" ], false).length,
		getPaths([ "start" ], adjacent, [ "start" ], true).length
	];
}

void main() {
	assert (solve("test") == [ 10, 36 ]);
	assert (solve("test2") == [ 19, 103 ]);
	writeln (solve("input"));
}
