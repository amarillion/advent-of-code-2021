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
import common.util;
import common.coordrange;

bool inside(Point pos, Point topLeft, Point bottomRight) {
	return pos.x >= topLeft.x &&
		pos.y >= topLeft.y &&
		pos.x <= bottomRight.x &&
		pos.y <= bottomRight.y;
}

auto solve (string fname) {
	string line = readLines(fname)[0]["target area: ".length..$];
	int[][] coords = line.split(", ").map!(s => s["x=".length..$].split("..").map!(to!int).array).array;
	
	Point topLeft = Point(coords[0][0], coords[1][0]);
	Point bottomRight = Point(coords[0][1], coords[1][1]);
	writeln(topLeft, bottomRight);
	
	int maxSuccess = int.min;

	foreach(initialV; PointRange(Point(0, 0), Point(100, 100))) {
		Point v = initialV;

		Point pos = Point(0, 0);
		
		void doStep() {
			pos = pos + v; // TODO: allow +=
			if (v.x < 0) v.x = v.x + 1; // TODO: allow +=
			if (v.x > 0) v.x = v.x - 1;
			v.y = v.y - 1;
		}

		int maxHeight = int.min;
		bool hit = false;
		while(pos.y >= bottomRight.y) {
			doStep();
			hit |= (pos.inside(topLeft, bottomRight));
			if (pos.y > maxHeight) {
				maxHeight = pos.y;
			}
		}

		writefln("InitialV: %s, hit: %s, maxHeight: %s", initialV, hit, maxHeight);

		if (hit && maxHeight > maxSuccess) {
			maxSuccess = maxHeight;
		}
	}

	return [ maxSuccess ];
}

void main() {

	assert (solve("test") == [ 45 ]);
	writeln (solve("input"));
}
