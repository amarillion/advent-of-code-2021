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
import common.util;
import common.coordrange;
import std.bigint;

struct Cuboid {
	vec3i lowestCorner;
	vec3i size;

	// use "auto ref const" to allow Lval and Rval here.
	int opCmp()(auto ref const Cuboid s) const {
		// sort first by pos, then by size
		if (lowestCorner == s.lowestCorner) {
			return size.opCmp(s.size);
		}
		return lowestCorner.opCmp(s.lowestCorner);
	}
}

bool inside(vec3i p, Cuboid a) {
	vec3i relative = p - a.lowestCorner;
	return (relative.x >= 0 && relative.y >= 0 && relative.z >= 0 &&
		relative.x <= a.size.x && relative.y <= a.size.y && relative.z <= a.size.z);
}

bool overlaps(Cuboid a, Cuboid b) {
	vec3i a1 = a.lowestCorner;
	vec3i a2 = a.lowestCorner + a.size;
	vec3i b1 = b.lowestCorner;
	vec3i b2 = b.lowestCorner + b.size;

	return a2.x > b1.x && a1.x < b2.x 
		&& a2.y > b1.y && a1.y < b2.y
		&& a2.z > b1.z && a1.z < b2.z;
}

Cuboid[] bisect(Cuboid a, int pos, int dim) {
	vec3i p1 = a.lowestCorner;
	vec3i p2 = a.lowestCorner + a.size;

	// doesn't bisect, return unchanged.
	if (pos <= p1.val[dim] || pos >= p2.val[dim]) {
		return [ a ];
	}

	vec3i s1 = a.size;
	s1.val[dim] = pos - p1.val[dim];
	vec3i s2 = a.size;
	s2.val[dim] = p2.val[dim] - pos;
	
	vec3i p15 = p1;
	p15.val[dim] = pos;

	assert(s1.x > 0 && s1.y > 0 && s1.z > 0);
	assert(s2.x > 0 && s2.y > 0 && s2.z > 0);
	return [
		Cuboid(p1, s1),
		Cuboid(p15, s2)
	];
}

// splits a & b in three lists: parts of a, overlapping, and parts of b.
// returns variable number of cubes, could be up to 27
Cuboid[][] intersections(Cuboid a, Cuboid b) {
	Cuboid[] aSplits = [ a ];
	Cuboid[] bSplits = [ b ];

	vec3i a1 = a.lowestCorner;
	vec3i a2 = a.lowestCorner + a.size;
	vec3i b1 = b.lowestCorner;
	vec3i b2 = b.lowestCorner + b.size;

	for (int dim = 0; dim < 3; ++dim) {
		aSplits = aSplits.map!(q => q.overlaps(b) ? q.bisect(b1.val[dim], dim).array : [ q ]).join.array;
		aSplits = aSplits.map!(q => q.overlaps(b) ? q.bisect(b2.val[dim], dim).array : [ q ]).join.array;
		bSplits = bSplits.map!(q => q.overlaps(a) ? q.bisect(a1.val[dim], dim).array : [ q ]).join.array;
		bSplits = bSplits.map!(q => q.overlaps(a) ? q.bisect(a2.val[dim], dim).array : [ q ]).join.array;
	}

	// determine overlapping
	sort (aSplits);
	sort (bSplits);
	Cuboid[] overlapping = aSplits.setIntersection(bSplits).array;
	aSplits = aSplits.setDifference(overlapping).array;
	bSplits = bSplits.setDifference(overlapping).array;
	return [
		aSplits,
		overlapping,
		bSplits
	];
}

BigInt volume(Cuboid a) {
	return to!BigInt(a.size.x) * to!BigInt(a.size.y) * to!BigInt(a.size.z);
}

void test() {	
	Cuboid a = Cuboid(vec3i(0, 0, 0), vec3i(5, 3, 4));
	Cuboid b = Cuboid(vec3i(-2, 1, 2), vec3i(5, 4, 3));
	Cuboid c = Cuboid(vec3i(1,1,1), vec3i(1,1,1));

	assert(a.volume == 60);
	assert(b.volume == 60);
	assert(c.volume == 1);
	
	vec3i p1 = vec3i(3, 1, 2);
	vec3i p2 = vec3i(8,0,0);

	assert(p1.inside(a));
	assert(p1.inside(b));
	assert(!p2.inside(a));
	assert(!p2.inside(b));
	
	assert(a.overlaps(a));
	assert(b.overlaps(b));
	assert(c.overlaps(c));

	assert(a.overlaps(b));
	assert(b.overlaps(a));
	assert(c.overlaps(a));
	assert(!c.overlaps(b));

	assert (intersections(a, b) == [
		[
			Cuboid(vec3i(0,0,0), vec3i(3,1,4)), 
			Cuboid(vec3i(3,0,0), vec3i(2,3,4)), 
			Cuboid(vec3i(0,1,0), vec3i(3,2,2)), 
		],
		[
			Cuboid(vec3i(0,1,2), vec3i(3,2,2)),
		],
		[
			Cuboid(vec3i(-2, 1, 2), vec3i(2, 4, 3)), 
			Cuboid(vec3i( 0, 3, 2), vec3i(3, 2, 3)), 
			Cuboid(vec3i( 0, 1, 4), vec3i(3, 2, 1)), 
		],
	]);

	assert (intersections(Cuboid(vec3i(0), vec3i(3,3,1)), Cuboid(vec3i(1,1,0), vec3i(1))) == [
		[
			Cuboid(vec3i(0,0,0), vec3i(1, 3, 1)), 
			Cuboid(vec3i(1,0,0), vec3i(1, 1, 1)), 
			Cuboid(vec3i(2,0,0), vec3i(1, 3, 1)), 
			Cuboid(vec3i(1,2,0), vec3i(1, 1, 1)), 
		],
		[
			Cuboid(vec3i(1,1,0), vec3i(1, 1, 1)),
		],
		[],
	]);

	assert(intersections(
		Cuboid(vec3i(5,0,0), vec3i(1, 10, 1)), 
		Cuboid(vec3i(0,5,0), vec3i(10, 1, 1)), 
	) == [
		[
			Cuboid(vec3i(5,0,0), vec3i(1, 5, 1)),
			Cuboid(vec3i(5,6,0), vec3i(1, 4, 1)),
		],
		[
			Cuboid(vec3i(5,5,0), vec3i(1, 1, 1)),
		],
		[
			Cuboid(vec3i(0,5,0), vec3i(5, 1, 1)),
			Cuboid(vec3i(6,5,0), vec3i(4, 1, 1)),
		]
	]);

	/*
	on x=10..12,y=10..12,z=10..12
	on x=11..13,y=11..13,z=11..13
	off x=9..11,y=9..11,z=9..11
	on x=10..10,y=10..10,z=10..10
	*/	
	Cuboid[] list = [];
	list = merge(list, Cuboid(vec3i(10,10,10), vec3i(3,3,3)), true);
	assert(list.map!volume.sum == 27);
	
	list = merge(list, Cuboid(vec3i(11,11,11), vec3i(3,3,3)), true);
	assert(list.map!volume.sum == 27 + 19);

	list = merge(list, Cuboid(vec3i(9,9,9), vec3i(3,3,3)), false);
	assert(list.map!volume.sum == 27 + 19 - 8);

	list = merge(list, Cuboid(vec3i(10,10,10), vec3i(1,1,1)), true);
	assert(list.map!volume.sum == 27 + 19 - 8 + 1);
}

Cuboid[][] breakup(Cuboid[] list, Cuboid cc) {
	Cuboid[] aList = list.dup;
	Cuboid[] bList = [ cc ];

	Cuboid[] aResult;
	Cuboid[] bResult;
	Cuboid[] overlapping;

	//TODO: this algorithm can probably be optimized
	while (aList.length > 0) {
		Cuboid a = aList.front;
		aList.popFront;
		bool overlapFound = false;
		Cuboid[] newBlist = [];
		foreach(b; bList) {
			if (a.overlaps(b)) {
				assert(!overlapFound); // shouldn't find two overlaps in one scan
				Cuboid[][] i = intersections(a, b);
				
				aList ~= i[0];
				overlapping ~= i[1];
				newBlist = bList.filter!(x => x != b).array ~ i[2];
				overlapFound = true;
				break;
			}
		}
		if (overlapFound) {
			bList = newBlist;
		}
		else {
			aResult ~= a;
		}
	}
	bResult = bList;
	
	BigInt[] v = [
		list.map!volume.sum,
		cc.volume,

		aResult.map!volume.sum,
		overlapping.map!volume.sum,
		bResult.map!volume.sum,
	];

	// sanity check: volumes of inputs and outputs should match
	assert(v[0] == v[2] + v[3]);
	assert(v[1] == v[3] + v[4]);
	assert(v[0] + v[1] == v[2] + 2 * v[3] + v[4]);
	return [
		aResult, overlapping, bResult
	];
}

auto merge(Cuboid[] list, Cuboid c, bool add) {
	Cuboid[][] brokenUp = breakup(list, c);
	Cuboid[] result;
	if (add) {
		result = brokenUp[0] ~ brokenUp[1] ~ brokenUp[2];
	}
	else {
		result = brokenUp[0];
	}
	return result;
}

auto solve (string fname, bool onlyBelowFifty) {
	string[] lines = readLines(fname);
	
	Cuboid[] onCubes = [];
	Cuboid fifty = Cuboid(vec3i(-50, -50, -50), vec3i(100, 100, 100));

	foreach(l, line; lines) {
		string[] fields = line.split(" ");
		bool turnOn = fields[0] == "on";
		int[][] coords = fields[1].split(",").map!(s => s["x=".length..$].split("..").map!(to!int).array).array;
		sort(coords[0]);
		sort(coords[1]);
		sort(coords[2]);
		vec3i p1 = vec3i(coords[0][0], coords[1][0], coords[2][0]);
		vec3i p2 = vec3i(coords[0][1], coords[1][1], coords[2][1]);
		if (onlyBelowFifty && !p1.inside(fifty)) continue;

		onCubes = merge(onCubes, Cuboid(p1, (p2 - p1) + 1), turnOn);
		writefln("line: %s, volume: %s, cubes: %s", l, onCubes.map!volume.sum, onCubes.length);
	}

	return [ onCubes.map!volume.sum ];
}

void main() {
	test();

	assert (solve("test", true) == [ 590_784 ]);
	assert (solve("test2", false) == [ BigInt("2758514936282235") ]);
	writeln (solve("input", false));
}
