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

vec3i[] corners(vec3i p1, vec3i p2) {
	return [
		vec3i(p1.x, p1.y, p1.z),
		vec3i(p1.x, p1.y, p2.z),
		vec3i(p1.x, p2.y, p1.z),
		vec3i(p1.x, p2.y, p2.z),
		vec3i(p2.x, p1.y, p1.z),
		vec3i(p2.x, p1.y, p2.z),
		vec3i(p2.x, p2.y, p1.z),
		vec3i(p2.x, p2.y, p2.z),
	];
}

vec3i[] corners(Cuboid a) {
	vec3i p1 = a.lowestCorner;
	vec3i p2 = a.lowestCorner + a.size;
	return corners(p1, p2);
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

Cuboid[] splitCuboid(Cuboid a, vec3i p) {
	if (!p.inside(a)) return [ a ];
	
	vec3i p1 = a.lowestCorner;
	vec3i p2 = p;
	vec3i p3 = a.lowestCorner + a.size;
	vec3i s1 = p2 - p1;
	vec3i s2 = p3 - p2;
	
	Cuboid[] result = [
		Cuboid(vec3i(p1.x, p1.y, p1.z), vec3i(s1.x, s1.y, s1.z)),
		Cuboid(vec3i(p2.x, p1.y, p1.z), vec3i(s2.x, s1.y, s1.z)),
		Cuboid(vec3i(p1.x, p2.y, p1.z), vec3i(s1.x, s2.y, s1.z)),
		Cuboid(vec3i(p2.x, p2.y, p1.z), vec3i(s2.x, s2.y, s1.z)),
		Cuboid(vec3i(p1.x, p1.y, p2.z), vec3i(s1.x, s1.y, s2.z)),
		Cuboid(vec3i(p2.x, p1.y, p2.z), vec3i(s2.x, s1.y, s2.z)),
		Cuboid(vec3i(p1.x, p2.y, p2.z), vec3i(s1.x, s2.y, s2.z)),
		Cuboid(vec3i(p2.x, p2.y, p2.z), vec3i(s2.x, s2.y, s2.z)),
	];
	result = result.filter!(c => c.volume > 0).array;
	return result;
}

// returns variable number, could be up to 27
Cuboid[][] intersections(Cuboid a, Cuboid b) {
	// make a list of overlapping points
	vec3i[] corners = a.corners ~ b.corners;
	Cuboid[] aSplits = [ a ];
	Cuboid[] bSplits = [ b ];
	foreach(p; corners) {
		aSplits = aSplits.map!(q => q.splitCuboid(p)).array.join.array;
		bSplits = bSplits.map!(q => q.splitCuboid(p)).array.join.array;
	}
	// determine overlapping
	sort (aSplits);
	sort (bSplits);
	Cuboid[] overlapping = aSplits.setIntersection(bSplits).array;
	aSplits = aSplits.setDifference(overlapping).array;
	bSplits = bSplits.setDifference(overlapping).array;
	// writefln("aSplits after splitting: %s", aSplits.length);
	// writefln("bSplits after splitting: %s", bSplits.length);
	// writefln("overlapping: %s", overlapping.length);
	return [
		aSplits,
		overlapping,
		bSplits
	];
}

ulong volume(Cuboid a) {
	return a.size.x * a.size.y * a.size.z;
}

vec3i[] allPoints(Cuboid c) {
	vec3i[] result = [];
	foreach(p; CoordRange!vec3i(c.lowestCorner, c.lowestCorner + c.size)) {
		result ~= p;
	}
	return result;
}

void test() {
	Cuboid a = Cuboid(vec3i(0, 0, 0), vec3i(5, 3, 4));
	Cuboid b = Cuboid(vec3i(-2, 1, 2), vec3i(5, 4, 3));
	Cuboid c = Cuboid(vec3i(1,1,1), vec3i(1,1,1));

	assert(a.volume == 60);
	assert(b.volume == 60);
	
	vec3i p1 = vec3i(3, 1, 2);
	vec3i p2 = vec3i(8,0,0);
	vec3i p3 = vec3i(0,3,4);

	assert(p1.inside(a));
	assert(p1.inside(b));
	assert(!p2.inside(a));
	assert(!p2.inside(b));
	assert(a.overlaps(b));
	assert(b.overlaps(a));
	assert(c.overlaps(a));
	assert(!c.overlaps(b));

	assert(a.splitCuboid(p2) == [ a ]);

	Cuboid[] aExpected = [
		Cuboid(vec3i(0,0,0), vec3i(3,1,2)), 
		Cuboid(vec3i(3,0,0), vec3i(2,1,2)), 
		Cuboid(vec3i(0,1,0), vec3i(3,2,2)), 
		Cuboid(vec3i(3,1,0), vec3i(2,2,2)), 		
		Cuboid(vec3i(0,0,2), vec3i(3,1,2)), 
		Cuboid(vec3i(3,0,2), vec3i(2,1,2)), 
		Cuboid(vec3i(0,1,2), vec3i(3,2,2)), 
		Cuboid(vec3i(3,1,2), vec3i(2,2,2)), 
	];
	assert (a.splitCuboid(p1) == aExpected);
	assert (a.volume == aExpected.map!volume.sum);

	Cuboid[] bExpected = [
		Cuboid(vec3i(-2, 1, 2), vec3i(2, 2, 2)), 
		Cuboid(vec3i( 0, 1, 2), vec3i(3, 2, 2)), 
		Cuboid(vec3i(-2, 3, 2), vec3i(2, 2, 2)), 
		Cuboid(vec3i( 0, 3, 2), vec3i(3, 2, 2)), 
		Cuboid(vec3i(-2, 1, 4), vec3i(2, 2, 1)), 
		Cuboid(vec3i( 0, 1, 4), vec3i(3, 2, 1)), 
		Cuboid(vec3i(-2, 3, 4), vec3i(2, 2, 1)), 
		Cuboid(vec3i( 0, 3, 4), vec3i(3, 2, 1)), 
	];
	assert (b.splitCuboid(p1) == [ b ]);
	assert (b.splitCuboid(p3) == bExpected);
	assert (b.volume == bExpected.map!volume.sum);

	assert (intersections(a, b) == [
		[
			Cuboid(vec3i(0,0,0), vec3i(3,1,2)), 
			Cuboid(vec3i(3,0,0), vec3i(2,1,2)), 
			Cuboid(vec3i(0,1,0), vec3i(3,2,2)), 
			Cuboid(vec3i(3,1,0), vec3i(2,2,2)), 		
			Cuboid(vec3i(0,0,2), vec3i(3,1,2)), 
			Cuboid(vec3i(3,0,2), vec3i(2,1,2)), 
			Cuboid(vec3i(3,1,2), vec3i(2,2,2)), 
		],
		[
			Cuboid(vec3i(0,1,2), vec3i(3,2,2)),
		],
		[
			Cuboid(vec3i(-2, 1, 2), vec3i(2, 2, 2)), 
			Cuboid(vec3i(-2, 3, 2), vec3i(2, 2, 2)), 
			Cuboid(vec3i( 0, 3, 2), vec3i(3, 2, 2)), 
			Cuboid(vec3i(-2, 1, 4), vec3i(2, 2, 1)), 
			Cuboid(vec3i( 0, 1, 4), vec3i(3, 2, 1)), 
			Cuboid(vec3i(-2, 3, 4), vec3i(2, 2, 1)), 
			Cuboid(vec3i( 0, 3, 4), vec3i(3, 2, 1)), 
		],
	]);

	writeln(intersections(Cuboid(vec3i(0), vec3i(3,3,1)), Cuboid(vec3i(1,1,0), vec3i(1)) ));

	assert (intersections(Cuboid(vec3i(0), vec3i(3,3,1)), Cuboid(vec3i(1,1,0), vec3i(1))) == [
		[
			Cuboid(vec3i(0,0,0), vec3i(1)), 
			Cuboid(vec3i(1,0,0), vec3i(1)), 
			Cuboid(vec3i(2,0,0), vec3i(1)), 
			Cuboid(vec3i(0,1,0), vec3i(1)), 		
			Cuboid(vec3i(2,1,0), vec3i(1)), 
			Cuboid(vec3i(0,2,0), vec3i(1)), 
			Cuboid(vec3i(1,2,0), vec3i(1)), 
			Cuboid(vec3i(2,2,0), vec3i(1)), 
		],
		[
			Cuboid(vec3i(1,1,0), vec3i(1)),
		],
		[],
	]);

	Cuboid[] list0 = [ Cuboid(vec3i(10,10,0), vec3i(2, 2, 1)) ];
	assert(list0.map!volume.sum == 4);
	
	list0 = merge(list0, Cuboid(vec3i(8,10,0), vec3i(2, 2, 1)), true);
	list0 = merge(list0, Cuboid(vec3i(10,8,0), vec3i(2, 2, 1)), true);
	list0 = merge(list0, Cuboid(vec3i(8,8,0), vec3i(2, 2, 1)), true);
	assert(list0.map!volume.sum == 16);
	
	list0 = merge(list0, Cuboid(vec3i(9,9,0), vec3i(2, 2, 1)), false);
	assert(list0.map!volume.sum == 12);

/*
on x=10..12,y=10..12,z=10..12
on x=11..13,y=11..13,z=11..13
off x=9..11,y=9..11,z=9..11
on x=10..10,y=10..10,z=10..10
*/


	Cuboid[] cc = [
		Cuboid(vec3i(10,10,10), vec3i(3,3,3)),
		Cuboid(vec3i(11,11,11), vec3i(3,3,3)),
		Cuboid(vec3i(9,9,9), vec3i(3,3,3)),
		Cuboid(vec3i(10,10,10), vec3i(1,1,1)),
	];

	
	// start again
	Cuboid[] list = [];
	list = merge(list, cc[0], true);
	assert(list.map!volume.sum == 27);
	
	list = merge(list, cc[1], true);
	assert(list.map!volume.sum == 27 + 19);

	list = merge(list, cc[2], false);
	assert(list.map!volume.sum == 27 + 19 - 8);

	list = merge(list, cc[3], true);
	writeln(list);
	assert(list.map!volume.sum == 27 + 19 - 8 + 1);
}

bool nonOverlapping(Cuboid[] list) {
	for(int i = 0; i + 1 < list.length; ++i) {
		for(int j = i + 1; j < list.length; ++j) {
			if (overlaps(list[i], list[j])) { return false; }
		}
	}
	return true;
}

Cuboid[][] breakup(Cuboid[] list, Cuboid cc) {
	Cuboid[] aList = list.dup;
	Cuboid[] bList = [ cc ];

	Cuboid[] aResult;
	Cuboid[] bResult;
	Cuboid[] overlapping;

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
	//TODO: shouldn't be necessary
	sort(aResult);
	aResult = uniq(aResult).array;

	sort(overlapping);
	overlapping = uniq(overlapping).array;

	sort(bResult);
	bResult = uniq(bResult).array;

	assert(nonOverlapping(aResult));
	assert(nonOverlapping(bResult));
	assert(nonOverlapping(overlapping));
	assert(nonOverlapping(aResult ~ overlapping ~ bResult));
	ulong[] v = [
		list.map!volume.sum,
		cc.volume,

		aResult.map!volume.sum,
		overlapping.map!volume.sum,
		bResult.map!volume.sum,
	];
	writeln(v);
	// writefln("%s\nLeft: %s\nIntersection: %s\nRight: %s", v, aResult.map!allPoints.join, overlapping.map!allPoints.join, bResult.map!allPoints.join);
	assert(v[0] == v[2] + v[3]);
	assert(v[1] == v[3] + v[4]);
	assert(v[0] + v[1] == v[2] + 2 * v[3] + v[4]);
	return [
		aResult, overlapping, bResult
	];
}

auto merge(Cuboid[] list, Cuboid c, bool add) {
	writefln("merging: add=%s cuboid=%s to list of length %s", add, c, list.length);
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

auto solve (string fname) {
	string[] lines = readLines(fname);
	
	Cuboid[] onCubes = [];
	Cuboid fifty = Cuboid(vec3i(-50, -50, -50), vec3i(100, 100, 100));

	foreach(line; lines) {
		// example: "on x=-20..26,y=-36..17,z=-47..7"
		string[] fields = line.split(" ");
		bool turnOn = fields[0] == "on";
		int[][] coords = fields[1].split(",").map!(s => s["x=".length..$].split("..").map!(to!int).array).array;
		sort(coords[0]);
		sort(coords[1]);
		sort(coords[2]);
		vec3i p1 = vec3i(coords[0][0], coords[1][0], coords[2][0]);
		vec3i p2 = vec3i(coords[0][1], coords[1][1], coords[2][1]);
		if (!p1.inside(fifty)) continue;

		onCubes = merge(onCubes, Cuboid(p1, (p2 - p1) + 1), turnOn);
	}

	return [ onCubes.map!volume.sum ];
}

void main() {
	test();

	assert (solve("test") == [ 590784 ]);
	writeln (solve("input"));
}
