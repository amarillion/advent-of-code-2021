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

int countPaths(string node, const Edge[] lines) {
	if (node == "end") { return 1; }
	
	int result = 0;
	// if this node is lowercase, filter it from remain set.
	bool dontReturn = (node.toLower() == node);
	const Edge[] remain = dontReturn ? 
		lines.filter!(edge => edge[0] != node && edge[1] != node).array :
		lines;

	// find all that start with this node
	foreach(line; lines) {

		if (line[0] == node) {
			writeln("Following ", node, " -> ", line[1], " ", remain);
			result += countPaths(line[1], remain);
		}
		else if (line[1] == node) {
			writeln("Following ", node, " -> ", line[0], " ", remain);
			result += countPaths(line[0], remain);
		}
	}
	return result;
}

auto solve (string fname) {
	string[] lines = readLines(fname);
	Edge[] edges = lines.map!(s => s.split("-")).array;
	writeln(edges);
	int count = countPaths("start", edges);
	return [ count ];
}

void main() {
	assert (solve("test") == [ 10 ]);
	assert (solve("test2") == [ 19 ]);
	writeln (solve("input"));
}
