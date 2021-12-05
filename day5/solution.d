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

bool isOrthogonal(Line l) { return l.a.x == l.b.x || l.a.y == l.b.y; }

Point kingsMove(Line line) {
	Point delta = line.b - line.a;
	return Point(sgn(delta.x), sgn(delta.y));
}

size_t countCrosspoints(Line[] lines) {
	auto grid = new SparseInfiniteGrid!(Point, int)();
	foreach (Line line; lines) {
		Point pos = line.a;
		Point delta = kingsMove(line);

		grid.set(pos, grid.get(pos) + 1);
		while (pos != line.b) {
			pos = pos + delta;
			grid.set(pos, grid.get(pos) + 1);
		}
	}
	return PointRange(grid.min, grid.max + 1).count!(pos => grid.get(pos) >= 2);
}

Point parsePoint(string s) {
	int[] values = s.split(",").map!(to!int).array;
	return Point(values[0], values[1]);
}
	
auto solve (string fname) {	
	string[] data = readLines(fname);
	Line[] lines = [];

	foreach(string d; data) {
		string[] fields = d.split(" -> ").array;
		lines ~= Line(parsePoint(fields[0]), parsePoint(fields[1]));
	}

	return [
		countCrosspoints(lines.filter!isOrthogonal.array),
		countCrosspoints(lines)
	];
}

void main() {
	assert (solve("test") == [ 5, 12 ]);
	writeln (solve("input"));
}
