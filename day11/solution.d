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
import common.grid;
import common.coordrange;

auto validDiagonals(T)(const Grid!T grid, const Point pos) {
	Point[] diagonals = [
		Point(0, 1), Point(1, 0), Point(0, -1), Point(-1, 0),
		Point(1, 1), Point(1, -1), Point(-1, 1), Point(-1, -1)
	];
	return new Generator!Point({
		foreach(delta; diagonals) {
			Point np = pos + delta;
			if (!grid.inRange(np)) continue;
			yield(np);
		}
	});
}

int step(Grid!int grid) {
	int flashCount = 0;
	Point[] flashPoints = [];

	void increaseEnergy(Point pos) {
		int val = grid.get(pos);
		if (val == 9) {
			flashPoints ~= pos;
			flashCount++;
		}
		grid.set(pos, val + 1);	
	}

	foreach(pos; PointRange(grid.size)) {
		increaseEnergy(pos);
	}

	while(flashPoints.length > 0) {
		Point fp = flashPoints.back;
		flashPoints.popBack;

		foreach(np; grid.validDiagonals(fp)) {
			increaseEnergy(np);
		}
	}

	// by going back to 0 at the end, we avoid double flashes
	grid.range.each!((ref val) { if (val >= 10) val = 0; });
	return flashCount;
}

auto solve (string fname) {
	string[] lines = readLines(fname);
	Point size = Point(to!int(lines[0].length), to!int(lines.length));
	Grid!int grid = new Grid!int(size.x, size.y);
	foreach(pos; PointRange(size)) {
		string digit = to!string(lines[pos.y][pos.x]);
		grid.set(pos, to!int(digit));
	}

	int[] flashCounts = [];
	int flashCount = 0;
	while (flashCount != grid.size.x * grid.size.y) {
		flashCount = step(grid);
		flashCounts ~= flashCount;
	}
	
	return [ flashCounts.take(100).sum, flashCounts.length ];
}

void main() {
	assert (solve("test") == [ 1656, 195 ]);
	writeln (solve("input"));
}
