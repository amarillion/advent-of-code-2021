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
import std.bigint;

alias vec3l = vec!(3, long);

struct Cuboid {
	vec3l lowestCorner;
	vec3l size;

	// use "auto ref const" to allow Lval and Rval here.
	int opCmp()(auto ref const Cuboid s) const {
		// sort first by pos, then by size
		if (lowestCorner == s.lowestCorner) {
			return size.opCmp(s.size);
		}
		return lowestCorner.opCmp(s.lowestCorner);
	}
}

bool inside(vec3l p, Cuboid a) {
	vec3l relative = p - a.lowestCorner;
	return (relative.x >= 0 && relative.y >= 0 && relative.z >= 0 &&
		relative.x <= a.size.x && relative.y <= a.size.y && relative.z <= a.size.z);
}

bool overlaps(Cuboid a, Cuboid b) {
	vec3l a1 = a.lowestCorner;
	vec3l a2 = a.lowestCorner + a.size;
	vec3l b1 = b.lowestCorner;
	vec3l b2 = b.lowestCorner + b.size;

	// writefln("[%s %s] [%s %s]", a1, a2, b1, b2);
	return a2.x > b1.x && a1.x < b2.x 
		&& a2.y > b1.y && a1.y < b2.y
		&& a2.z > b1.z && a1.z < b2.z;
}

Cuboid[] bisect(Cuboid a, long pos, int dim) {
	vec3l p1 = a.lowestCorner;
	vec3l p2 = a.lowestCorner + a.size;

	// doesn't bisect, return unchanged.
	if (pos <= p1.val[dim] || pos >= p2.val[dim]) {
		return [ a ];
	}

	vec3l s1 = a.size;
	s1.val[dim] = pos - p1.val[dim];
	vec3l s2 = a.size;
	s2.val[dim] = p2.val[dim] - pos;
	
	vec3l p15 = p1;
	p15.val[dim] = pos;

	assert(s1.x > 0 && s1.y > 0 && s1.z > 0);
	assert(s2.x > 0 && s2.y > 0 && s2.z > 0);
	return [
		Cuboid(p1, s1),
		Cuboid(p15, s2)
	];
}

// returns variable number, could be up to 27
Cuboid[][] intersections(Cuboid a, Cuboid b) {
	Cuboid[] aSplits = [ a ];
	Cuboid[] bSplits = [ b ];

	vec3l a1 = a.lowestCorner;
	vec3l a2 = a.lowestCorner + a.size;
	vec3l b1 = b.lowestCorner;
	vec3l b2 = b.lowestCorner + b.size;

	for (int dim = 0; dim < 3; ++dim) {
		aSplits = aSplits.map!(q => q.bisect(b1.val[dim], dim)).array.join.array;
		aSplits = aSplits.map!(q => q.bisect(b2.val[dim], dim)).array.join.array;
		bSplits = bSplits.map!(q => q.bisect(a1.val[dim], dim)).array.join.array;
		bSplits = bSplits.map!(q => q.bisect(a2.val[dim], dim)).array.join.array;
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

BigInt volume(Cuboid a) {
	return to!BigInt(a.size.x) * to!BigInt(a.size.y) * to!BigInt(a.size.z);
}

vec3l[] allPoints(Cuboid c) {
	vec3l[] result = [];
	foreach(p; CoordRange!vec3l(c.lowestCorner, c.lowestCorner + c.size)) {
		result ~= p;
	}
	return result;
}

void test() {
	Cuboid c1 = Cuboid(vec3l(37771, 34417, -47992), vec3l(21006, 28158, 24891));
	Cuboid c2 = Cuboid(vec3l(36305, 41145, -42601), vec3l(37933, 11090, 14106)); 
	assert(overlaps(c1, c2));
	// TODO: bugged - there should be an intersection...	
	// writeln(intersections(c1, c2));
	assert(intersections(c1, c2) != [[c1],[], [c2]]);
	
	Cuboid a = Cuboid(vec3l(0, 0, 0), vec3l(5, 3, 4));
	Cuboid b = Cuboid(vec3l(-2, 1, 2), vec3l(5, 4, 3));
	Cuboid c = Cuboid(vec3l(1,1,1), vec3l(1,1,1));

	assert(a.volume == 60);
	assert(b.volume == 60);
	
	vec3l p1 = vec3l(3, 1, 2);
	vec3l p2 = vec3l(8,0,0);
	vec3l p3 = vec3l(0,3,4);

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

	// assert(a.bisect(8, 1) == [ a ]);

	// Cuboid[] aExpected = [
	// 	Cuboid(vec3l(0,0,0), vec3l(3,1,2)), 
	// 	Cuboid(vec3l(3,0,0), vec3l(2,1,2)), 
	// 	Cuboid(vec3l(0,1,0), vec3l(3,2,2)), 
	// 	Cuboid(vec3l(3,1,0), vec3l(2,2,2)), 		
	// 	Cuboid(vec3l(0,0,2), vec3l(3,1,2)), 
	// 	Cuboid(vec3l(3,0,2), vec3l(2,1,2)), 
	// 	Cuboid(vec3l(0,1,2), vec3l(3,2,2)), 
	// 	Cuboid(vec3l(3,1,2), vec3l(2,2,2)), 
	// ];
	// assert (a.splitCuboid(p1) == aExpected);
	// assert (a.volume == aExpected.map!volume.sum);

	// Cuboid[] bExpected = [
	// 	Cuboid(vec3l(-2, 1, 2), vec3l(2, 2, 2)), 
	// 	Cuboid(vec3l( 0, 1, 2), vec3l(3, 2, 2)), 
	// 	Cuboid(vec3l(-2, 3, 2), vec3l(2, 2, 2)), 
	// 	Cuboid(vec3l( 0, 3, 2), vec3l(3, 2, 2)), 
	// 	Cuboid(vec3l(-2, 1, 4), vec3l(2, 2, 1)), 
	// 	Cuboid(vec3l( 0, 1, 4), vec3l(3, 2, 1)), 
	// 	Cuboid(vec3l(-2, 3, 4), vec3l(2, 2, 1)), 
	// 	Cuboid(vec3l( 0, 3, 4), vec3l(3, 2, 1)), 
	// ];
	// assert (b.splitCuboid(p1) == [ b ]);
	// assert (b.splitCuboid(p3) == bExpected);
	// assert (b.volume == bExpected.map!volume.sum);

	assert (intersections(a, b) == [
		[
			Cuboid(vec3l(0,0,0), vec3l(3,1,2)), 
			Cuboid(vec3l(3,0,0), vec3l(2,1,2)), 
			Cuboid(vec3l(0,1,0), vec3l(3,2,2)), 
			Cuboid(vec3l(3,1,0), vec3l(2,2,2)), 		
			Cuboid(vec3l(0,0,2), vec3l(3,1,2)), 
			Cuboid(vec3l(3,0,2), vec3l(2,1,2)), 
			Cuboid(vec3l(3,1,2), vec3l(2,2,2)), 
		],
		[
			Cuboid(vec3l(0,1,2), vec3l(3,2,2)),
		],
		[
			Cuboid(vec3l(-2, 1, 2), vec3l(2, 2, 2)), 
			Cuboid(vec3l(-2, 3, 2), vec3l(2, 2, 2)), 
			Cuboid(vec3l( 0, 3, 2), vec3l(3, 2, 2)), 
			Cuboid(vec3l(-2, 1, 4), vec3l(2, 2, 1)), 
			Cuboid(vec3l( 0, 1, 4), vec3l(3, 2, 1)), 
			Cuboid(vec3l(-2, 3, 4), vec3l(2, 2, 1)), 
			Cuboid(vec3l( 0, 3, 4), vec3l(3, 2, 1)), 
		],
	]);

	// writeln(intersections(Cuboid(vec3l(0), vec3l(3,3,1)), Cuboid(vec3l(1,1,0), vec3l(1)) ));

	assert (intersections(Cuboid(vec3l(0), vec3l(3,3,1)), Cuboid(vec3l(1,1,0), vec3l(1))) == [
		[
			Cuboid(vec3l(0,0,0), vec3l(1)), 
			Cuboid(vec3l(1,0,0), vec3l(1)), 
			Cuboid(vec3l(2,0,0), vec3l(1)), 
			Cuboid(vec3l(0,1,0), vec3l(1)), 		
			Cuboid(vec3l(2,1,0), vec3l(1)), 
			Cuboid(vec3l(0,2,0), vec3l(1)), 
			Cuboid(vec3l(1,2,0), vec3l(1)), 
			Cuboid(vec3l(2,2,0), vec3l(1)), 
		],
		[
			Cuboid(vec3l(1,1,0), vec3l(1)),
		],
		[],
	]);

	assert(overlaps(
		Cuboid(vec3l(5,0,0), vec3l(1, 10, 1)), 
		Cuboid(vec3l(0,5,0), vec3l(10, 1, 1)), 
	));
	assert(!overlaps(
		Cuboid(vec3l(0,0,0), vec3l(1, 10, 1)), 
		Cuboid(vec3l(1,0,0), vec3l(1, 10, 1)), 
	));

	Cuboid[] list0 = [ Cuboid(vec3l(10,10,0), vec3l(2, 2, 1)) ];
	assert(list0.map!volume.sum == 4);
	
	list0 = merge(list0, Cuboid(vec3l(8,10,0), vec3l(2, 2, 1)), true);
	list0 = merge(list0, Cuboid(vec3l(10,8,0), vec3l(2, 2, 1)), true);
	list0 = merge(list0, Cuboid(vec3l(8,8,0), vec3l(2, 2, 1)), true);
	assert(list0.map!volume.sum == 16);
	
	list0 = merge(list0, Cuboid(vec3l(9,9,0), vec3l(2, 2, 1)), false);
	assert(list0.map!volume.sum == 12);

/*
on x=10..12,y=10..12,z=10..12
on x=11..13,y=11..13,z=11..13
off x=9..11,y=9..11,z=9..11
on x=10..10,y=10..10,z=10..10
*/


	Cuboid[] cc = [
		Cuboid(vec3l(10,10,10), vec3l(3,3,3)),
		Cuboid(vec3l(11,11,11), vec3l(3,3,3)),
		Cuboid(vec3l(9,9,9), vec3l(3,3,3)),
		Cuboid(vec3l(10,10,10), vec3l(1,1,1)),
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
	// writeln(list);
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

	// int ii = 0;
	while (aList.length > 0) {
		Cuboid a = aList.front;
		aList.popFront;
		bool overlapFound = false;
		Cuboid[] newBlist = [];
		foreach(b; bList) {
			// ii++;
			// if (ii % 1000 == 0) write(".");
			if (a.overlaps(b)) {
				assert(!overlapFound); // shouldn't find two overlaps in one scan
				// writefln("Get intersections %s %s", a, b);
				Cuboid[][] i = intersections(a, b);
				
				if (i[0] == [a] && i[2] == [b]) continue; // no overlap after all due to bug
				
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

	// assert(nonOverlapping(aResult));
	// assert(nonOverlapping(bResult));
	// assert(nonOverlapping(overlapping));
	// assert(nonOverlapping(aResult ~ overlapping ~ bResult));
	BigInt[] v = [
		list.map!volume.sum,
		cc.volume,

		aResult.map!volume.sum,
		overlapping.map!volume.sum,
		bResult.map!volume.sum,
	];
	// writeln(v);
	// writefln("%s\nLeft: %s\nIntersection: %s\nRight: %s", v, aResult.map!allPoints.join, overlapping.map!allPoints.join, bResult.map!allPoints.join);
	assert(v[0] == v[2] + v[3]);
	assert(v[1] == v[3] + v[4]);
	assert(v[0] + v[1] == v[2] + 2 * v[3] + v[4]);
	return [
		aResult, overlapping, bResult
	];
}

auto merge(Cuboid[] list, Cuboid c, bool add) {
	// writefln("merging: add=%s cuboid=%s to list of length %s", add, c, list.length);
	Cuboid[][] brokenUp = breakup(list, c);
	// writeln("Breakup done");
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
	Cuboid fifty = Cuboid(vec3l(-50, -50, -50), vec3l(100, 100, 100));

	foreach(l, line; lines) {
		string[] fields = line.split(" ");
		bool turnOn = fields[0] == "on";
		int[][] coords = fields[1].split(",").map!(s => s["x=".length..$].split("..").map!(to!int).array).array;
		sort(coords[0]);
		sort(coords[1]);
		sort(coords[2]);
		vec3l p1 = vec3l(coords[0][0], coords[1][0], coords[2][0]);
		vec3l p2 = vec3l(coords[0][1], coords[1][1], coords[2][1]);
		if (onlyBelowFifty && !p1.inside(fifty)) continue;

		onCubes = merge(onCubes, Cuboid(p1, (p2 - p1) + 1), turnOn);
		writeln(l, " ", onCubes.map!volume.sum);
	}

	return [ onCubes.map!volume.sum ];
}

void main() {
	test();

	assert (solve("test", true) == [ 590784 ]);
	assert (solve("test2", false) == [ BigInt("2758514936282235") ]);
	writeln (solve("input", false));
}
