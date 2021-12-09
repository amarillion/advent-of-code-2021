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
	Point(0, 1), Point(1, 0), Point(0, -1), Point(-1, 0)
];

size_t basinSize(Grid!int grid, Point lowest) {
	Point[] stack;
	bool[Point] visited;

	stack ~= lowest;
	visited[lowest] = true;

	while(stack.length > 0) {
		Point pos = stack[0]; 
		stack.popFront();

		foreach(a; adjacents) {
			Point np = pos + a;
			if (!grid.inRange(np)) continue;
			if (np in visited) continue;
			if (grid.get(np) == 9) continue; // assumption: borders are always nines

			stack ~= np;
			visited[np] = true;
		}
	}

	return visited.length;
}

Point[] lowPoints (Grid!int grid) {
	bool isLocalLowest(Point pos) {
		foreach(Point adjacent; adjacents) {
			if (grid.inRange(pos + adjacent)
				&& grid.get(pos + adjacent) <= grid.get(pos)
			) {
				return false;
			}
		}
		return true;
	}

	return PointRange(grid.size).filter!(p => isLocalLowest(p)).array;
}

auto solve (string fname) {
	string[] lines = readLines(fname);
	Point size = Point(to!int(lines[0].length), to!int(lines.length));
	Grid!int grid = new Grid!int(size.x, size.y);
	foreach(pos; PointRange(size)) {
		string digit = to!string(lines[pos.y][pos.x]);
		grid.set(pos, to!int(digit));
	}

	Point[] lowest = lowPoints(grid);
	size_t[] basins = lowest.map!(p => basinSize(grid, p)).array;
	sort!"a > b"(basins);

	return [
		lowest.map!(p => grid.get(p) + 1).sum(),
		basins[0] * basins[1] * basins[2]
	];
}

void main() {
	assert (solve("test") == [ 15, 1134 ]);
	writeln (solve("input"));
}
