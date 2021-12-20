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
import common.grid;
import common.coordrange;

alias MyGrid = Grid!char;

MyGrid transform(MyGrid input, string rule, int counter) {
	MyGrid result = new MyGrid(input.size + 2);
	foreach(pos; PointRange(result.size)) {
		result.set(pos, '.');
	}

	char defaultVal = counter % 2 == 0 ? '.' : rule[0];
	foreach(pos; PointRange(result.size)) {
		int code = 0;
		foreach (delta; PointRange(Point(-1), Point(2))) {
			code *= 2;
			Point np = pos + delta - 1;
			char val = input.inRange(np) ? input.get(np) : defaultVal; 
			if (val == '#') {
				code += 1;
			}
		}
		assert(code >= 0 && code <= rule.length);
		// writeln(pos, " ", code);
		result.set(pos, rule[code]);
	}
	return result;
}

auto solve (string fname) {
	string[] lines = readLines(fname);
	
	string rule = lines[0];
	assert(rule.length == 512);

	string[] image = lines[2..$];
	Point size = Point(to!int(image[0].length), to!int(image.length));
	
	Grid!char grid = new Grid!char(size.x, size.y);
	foreach(pos; PointRange(grid.size)) {
		grid.set(pos, '.');
	}
	foreach(pos; PointRange(size)) {
		char ch = image[pos.y][pos.x];
		grid.set(pos, ch);
	}

	grid = transform(grid, rule, 0);
	grid = transform(grid, rule, 1);
	
	auto part1 = grid.range.count('#');
	return [ part1 ];
}

void main() {
	assert (solve("test") == [ 35 ]);
	writeln (solve("input")); // not: 5127, not 5392
}
