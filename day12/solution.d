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

Path[] getPaths(string[] path, Edge[] lines, bool canRevisit) {
	string node = path.back;
	if (node == "end") { return [ path ]; }
	
	Path[] result = [];
	// if this node is lowercase, filter it from remain set.
	bool isSmallCave(string n) { return n.toLower() == n; }

	bool dontReturn = false;
	Edge[] remain = lines;

	if (isSmallCave(node)) {
		if (!canRevisit || node == "start") {
			remain = lines.filter!(edge => edge[0] != node && edge[1] != node).array;
		}
		else {
			bool isRevisit = path[0..$-1].canFind(node);
			if (isRevisit) {
				dontReturn = true;
				// filter out all visited lowercase caves now
				foreach(filterNode; path) {
					if (isSmallCave(filterNode)) {
						remain = remain.filter!(edge => edge[0] != filterNode && edge[1] != filterNode).array;
					}
				}
				canRevisit = false;
			}
		}
	}

	// find all that start with this node
	foreach(line; lines) {
		if (line[0] == node) {
			result ~= getPaths(path ~ line[1], remain, canRevisit);
		}
		else if (line[1] == node) {
			result ~= getPaths(path ~ line[0], remain, canRevisit);
		}
	}
	return result;
}

auto solve (string fname) {
	string[] lines = readLines(fname);
	Edge[] edges = lines.map!(s => s.split("-")).array;
	
	Path[] paths1 = getPaths(["start"], edges, false);
	Path[] paths2 = getPaths(["start"], edges, true);
	return [ paths1.length, paths2.length ];
}

void main() {
	assert (solve("test") == [ 10, 36 ]);
	assert (solve("test2") == [ 19, 103 ]);
	writeln (solve("input"));
}
