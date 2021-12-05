#!/usr/bin/env -S rdmd -I..

import common.io;
import common.grid;
import common.vec;
import std.stdio;
import std.string;
import std.conv;
import std.algorithm;
import std.array;
import std.range;
import std.functional;
import std.math;

struct Line {
	Point a;
	Point b;
}

auto solve (string fname) {	
	string[] data = readLines(fname);
	Line[] lines = [];

	foreach(string d; data) {
		string[] fields = d.split(" -> ").array;
		Line line;
		int[] values = fields[0].split(",").map!(to!int).array;
		line.a = Point(values[0], values[1]);
		values = fields[1].split(",").map!(to!int).array;
		line.b = Point(values[0], values[1]);
		lines ~= line;
	}
	
	auto grid = new SparseInfiniteGrid!(Point, int)();

	foreach (Line line; lines) {
		Point pos = line.a;
		Point delta = line.b - line.a;
		
		// if (delta.x != 0 && delta.y != 0) continue; // only consider horizontal / vertical

		if (delta.x != 0) delta.x = delta.x / abs(delta.x);
		if (delta.y != 0) delta.y = delta.y / abs(delta.y);		
		
		grid.set(pos, grid.get(pos) + 1);
		while (pos != line.b) {
			pos = pos + delta;
			grid.set(pos, grid.get(pos) + 1);
		}
	}
	
	int count = 0;
	foreach (Point pos; PointRange(grid.min, grid.max + 1)) {
		if (grid.get(pos) >= 2) {
			count++;
		}
	}
	// writeln(grid);
	return [ count ];
}

void main() {
	assert (solve("test") == [ /* 5 */ 12 ]);
	writeln (solve("input"));
}
