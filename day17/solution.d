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
	
	Point p1 = Point(coords[0][0], coords[1][0]);
	Point p2 = Point(coords[0][1], coords[1][1]);
	Point bottomLeft = Point(min(p1.x, p2.x), min(p1.y, p2.y));
	Point topRight = Point(max(p1.x, p2.x), max(p1.y, p2.y));
	// writeln(bottomLeft, topRight);

	int maxSuccess = int.min;
	Point[] successes = [];

	foreach(initialV; PointRange(Point(0, -400), Point(400, 400))) {
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
		while(pos.y >= bottomLeft.y) {
			doStep();
			hit |= (pos.inside(bottomLeft, topRight));
			if (pos.y > maxHeight) {
				maxHeight = pos.y;
			}
			// writefln("Pos: %s, v: %s", pos, v);
		}

		// writefln("InitialV: %s, hit: %s, maxHeight: %s", initialV, hit, maxHeight);

		if (hit && maxHeight > maxSuccess) {
			maxSuccess = maxHeight;
		}
		if (hit) { successes ~= initialV; }
	}

	// Point[] expected = [Point(23,-10), Point(25,-9), Point(27,-5), Point(29,-6), Point(22,-6), Point(21,-7), Point(9,0), Point(27,-7), Point(24,-5), Point(25,-7), Point(26,-6), Point(25,-5), Point(6,8), Point(11,-2), Point(20,-5), Point(29,-10), Point(6,3), Point(28,-7), Point(8,0), Point(30,-6), Point(29,-8), Point(20,-10), Point(6,7), Point(6,4), Point(6,1), Point(14,-4), Point(21,-6), Point(26,-10), Point(7,-1), Point(7,7), Point(8,-1), Point(21,-9), Point(6,2), Point(20,-7), Point(30,-10), Point(14,-3), Point(20,-8), Point(13,-2), Point(7,3), Point(28,-8), Point(29,-9), Point(15,-3), Point(22,-5), Point(26,-8), Point(25,-8), Point(25,-6), Point(15,-4), Point(9,-2), Point(15,-2), Point(12,-2), Point(28,-9), Point(12,-3), Point(24,-6), Point(23,-7), Point(25,-10), Point(7,8), Point(11,-3), Point(26,-7), Point(7,1), Point(23,-9), Point(6,0), Point(22,-10), Point(27,-6), Point(8,1), Point(22,-8), Point(13,-4), Point(7,6), Point(28,-6), Point(11,-4), Point(12,-4), Point(26,-9), Point(7,4), Point(24,-10), Point(23,-8), Point(30,-8), Point(7,0), Point(9,-1), Point(10,-1), Point(26,-5), Point(22,-9), Point(6,5), Point(7,5), Point(23,-6), Point(28,-10), Point(10,-2), Point(11,-1), Point(20,-9), Point(14,-2), Point(29,-7), Point(13,-3), Point(23,-5), Point(24,-8), Point(27,-9), Point(30,-7), Point(28,-5), Point(21,-10), Point(7,9), Point(6,6), Point(21,-5), Point(27,-10), Point(7,2), Point(30,-9), Point(21,-8), Point(22,-7), Point(24,-9), Point(20,-6), Point(6,9), Point(29,-5), Point(8,-2), Point(27,-8), Point(30,-5), Point(24,-7) ];
	// sort(expected);
	// sort(successes);

	// writeln("Difference 1: ", setDifference(expected, successes));
	// writeln("Difference 2: ", setDifference(successes, expected));
	// writeln(successes.length);
	return [ maxSuccess, successes.length ];
}


void main() {

	assert (solve("test") == [ 45, 112 ]);
	writeln (solve("input"));
}
