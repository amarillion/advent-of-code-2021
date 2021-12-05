#!/usr/bin/env -S rdmd -I..

import common.io;
import common.grid;
import common.vec;
import std.stdio;
import std.conv;
import std.algorithm;
import std.array;

alias Line = Point[2];
bool isOrthogonal(Line l) { return l[0].x == l[1].x || l[0].y == l[1].y; }

size_t countCrosspoints(Line[] lines) {
	auto grid = new SparseInfiniteGrid!(Point, int);
	foreach (Line line; lines) {
		foreach(Point pos; DiagonalWalker(line[0], line[1])) {
			grid.modify(pos, v => v + 1);
		}
	}
	return PointRange(grid.min, grid.max + 1).count!(pos => grid.get(pos) >= 2);
}

Point parsePoint(string s) {
	int[] values = s.split(",").map!(to!int).array;
	return Point(values[0], values[1]);
}
	
auto solve (string fname) {
	Line[] lines = readLines(fname).map!((d) {
		string[] fields = d.split(" -> ").array;
		Line l = [ parsePoint(fields[0]), parsePoint(fields[1]) ];
		return l;
	}).array;

	return [
		countCrosspoints(lines.filter!isOrthogonal.array),
		countCrosspoints(lines)
	];
}

void main() {
	assert (solve("test") == [ 5, 12 ]);
	writeln (solve("input"));
}
