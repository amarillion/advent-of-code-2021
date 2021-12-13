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
import common.sparsegrid;

Point[] doFold(string fold, Point[] dots) {
	string[] parts = fold.split("=");
	bool horizontal = (parts[0] == "fold along y");
	int pos = to!int(parts[1]);

	Point[] ndots = [];
	foreach(dot; dots) {
		if (horizontal) {
			if (dot.y > pos) {
				ndots ~= Point(dot.x, pos - (dot.y - pos));
			}
			else ndots ~= dot;
		}
		else {
			if (dot.x > pos) {
				ndots ~= Point(pos - (dot.x - pos), dot.y);
			}
			else ndots ~= dot;
		}
	}
	// sort and uniq
	sort(ndots);
	return uniq(ndots).array;
}

auto solve (string fname) {
	string[] lines = readLines(fname);
	size_t sep = indexOf(lines, "");

	Point[] dots = lines[0..sep].map!((l) { int[] cc = l.split(",").map!(to!int).array; return Point(cc[0], cc[1]); }).array;
	string[] folds = lines[sep+1..$];
	
	sort(dots);
	Point[] dots2 = doFold(folds[0], dots);
	
	Point[] ndots = dots.dup;
	foreach (fold; folds) {
		ndots = doFold(fold, ndots);
	}

	auto grid = new SparseInfiniteGrid!(Point, char)();
	foreach(dot; ndots) {
		grid.set(dot, '.');
	}

	writeln(grid.format(""));

	return [
		dots2.length
	];
}

void main() {
	assert (solve("test") == [ 17 ]);
	writeln (solve("input"));
}
