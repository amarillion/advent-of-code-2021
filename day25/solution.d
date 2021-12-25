#!/usr/bin/env -S rdmd -O -I..

import common.io;
import std.stdio;
import std.conv;
import std.algorithm;
import std.array;
import std.math;
import std.range;
import std.typecons;
import std.format;
import common.grid;
import common.vec;
import common.coordrange;

auto solve(string fname) {
	string[] lines = readLines(fname);	
	Point size = Point(to!int(lines[0].length), to!int(lines.length));
	
	Grid!char grid = new Grid!char(size.x, size.y);
	foreach(pos; PointRange(grid.size)) {
		grid.set(pos, lines[pos.y][pos.x]);
	}

	writeln("Initial state");
	writeln(grid.format(""));

	int step = 0;	

	while(true) {
		step++;

		int moveCount = 0;
		Point[] toMove = [];
		foreach(pos; PointRange(grid.size)) {
			Point to = Point((pos.x + 1) % size.x, pos.y);
			if (grid.get(pos) == '>' && grid.get(to) == '.') {
				toMove ~= pos;
				moveCount++;
			}
		}
		foreach(pos; toMove) {
			Point to = Point((pos.x + 1) % size.x, pos.y);
			grid.set(pos, '.');
			grid.set(to, '>');
		}

		toMove = [];
		foreach(pos; PointRange(grid.size)) {
			Point to = Point(pos.x, (pos.y + 1) % size.y);
			if (grid.get(pos) == 'v' && grid.get(to) == '.') {
				toMove ~= pos;
				moveCount++;
			}
		}
		foreach(pos; toMove) {
			Point to = Point(pos.x, (pos.y + 1) % size.y);
			grid.set(pos, '.');
			grid.set(to, 'v');
		}
		writefln("After %s step(s)", step);
		writeln(grid.format(""));	
		if (moveCount == 0) { break; }
	}

	return [ step ];
}

void main() {
	assert(solve("test") == [58]);
	writeln(solve("input"));
}
