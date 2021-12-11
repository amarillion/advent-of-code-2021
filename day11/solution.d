#!/usr/bin/env -S rdmd -I..

import common.io;
import common.vec;
import std.stdio;
import std.conv;
import std.algorithm;
import std.array;
import std.concurrency;
import std.math;
import std.ascii;
import common.grid;
import common.coordrange;

Point[] adjacents = [
	Point(0, 1), Point(1, 0), Point(0, -1), Point(-1, 0),
	Point(1, 1), Point(1, -1), Point(-1, 1), Point(-1, -1)
];

int step(Grid!int grid) {
	int result = 0;
	Point[] flashPoints = [];

	void increaseEnergy(Point pos) {
		int val = grid.get(pos);
		if (val == 9) {
			writeln("Flash at ", pos);
			flashPoints ~= pos;
			result++;
		}
		grid.set(pos, val + 1);	
	}

	foreach(pos; PointRange(grid.size)) {
		increaseEnergy(pos);
	}

	while(flashPoints.length > 0) {
		Point fp = flashPoints.back;
		flashPoints.popBack;

		foreach(delta; adjacents) {
			Point np = fp + delta;
			if (!grid.inRange(np)) continue;
			increaseEnergy(np);
		}
	}

	foreach(pos; PointRange(grid.size)) {
		if (grid.get(pos) >= 10) {
			grid.set(pos, 0);
		}
	}

	return result;
}

auto solve (string fname) {
	string[] lines = readLines(fname);
	Point size = Point(to!int(lines[0].length), to!int(lines.length));
	Grid!int grid = new Grid!int(size.x, size.y);
	foreach(pos; PointRange(size)) {
		string digit = to!string(lines[pos.y][pos.x]);
		grid.set(pos, to!int(digit));
	}

	int flashes = 0;
	for (int i = 0; i < 100; ++i) {
		
		// writeln("Step: ", i);
		// writeln(grid);
		flashes += step(grid);
	}

	return [
		flashes
	];
}

void main() {
	assert (solve("test") == [ 1656 ]);
	writeln (solve("input"));
}
