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

alias Matrix = int[3][3];

Matrix[] orientations = [

	[[ 1,  0,  0], [ 0,  1,  0], [ 0,  0,  1]],
	[[ 1,  0,  0], [ 0,  0,  1], [ 0,  1,  0]],
	[[ 0,  1,  0], [ 1,  0,  0], [ 0,  0,  1]],
	[[ 0,  1,  0], [ 0,  0,  1], [ 1,  0,  0]],
	[[ 0,  0,  1], [ 1,  0,  0], [ 0,  1,  0]],
	[[ 0,  0,  1], [ 0,  1,  0], [ 1,  0,  0]],

	[[ 1,  0,  0], [ 0,  1,  0], [ 0,  0, -1]],
	[[ 1,  0,  0], [ 0,  0,  1], [ 0, -1,  0]],
	[[ 0,  1,  0], [ 1,  0,  0], [ 0,  0, -1]],
	[[ 0,  1,  0], [ 0,  0,  1], [-1,  0,  0]],
	[[ 0,  0,  1], [ 1,  0,  0], [ 0, -1,  0]],
	[[ 0,  0,  1], [ 0,  1,  0], [-1,  0,  0]],

	[[ 1,  0,  0], [ 0, -1,  0], [ 0,  0,  1]],
	[[ 1,  0,  0], [ 0,  0, -1], [ 0,  1,  0]],
	[[ 0,  1,  0], [-1,  0,  0], [ 0,  0,  1]],
	[[ 0,  1,  0], [ 0,  0, -1], [ 1,  0,  0]],
	[[ 0,  0,  1], [-1,  0,  0], [ 0,  1,  0]],
	[[ 0,  0,  1], [ 0, -1,  0], [ 1,  0,  0]],

	[[ 1,  0,  0], [ 0, -1,  0], [ 0,  0, -1]],
	[[ 1,  0,  0], [ 0,  0, -1], [ 0, -1,  0]],
	[[ 0,  1,  0], [-1,  0,  0], [ 0,  0, -1]],
	[[ 0,  1,  0], [ 0,  0, -1], [-1,  0,  0]],
	[[ 0,  0,  1], [-1,  0,  0], [ 0, -1,  0]],
	[[ 0,  0,  1], [ 0, -1,  0], [-1,  0,  0]],


	[[-1,  0,  0], [ 0,  1,  0], [ 0,  0,  1]],
	[[-1,  0,  0], [ 0,  0,  1], [ 0,  1,  0]],
	[[ 0, -1,  0], [ 1,  0,  0], [ 0,  0,  1]],
	[[ 0, -1,  0], [ 0,  0,  1], [ 1,  0,  0]],
	[[ 0,  0, -1], [ 1,  0,  0], [ 0,  1,  0]],
	[[ 0,  0, -1], [ 0,  1,  0], [ 1,  0,  0]],

	[[-1,  0,  0], [ 0,  1,  0], [ 0,  0, -1]],
	[[-1,  0,  0], [ 0,  0,  1], [ 0, -1,  0]],
	[[ 0, -1,  0], [ 1,  0,  0], [ 0,  0, -1]],
	[[ 0, -1,  0], [ 0,  0,  1], [-1,  0,  0]],
	[[ 0,  0, -1], [ 1,  0,  0], [ 0, -1,  0]],
	[[ 0,  0, -1], [ 0,  1,  0], [-1,  0,  0]],

	[[-1,  0,  0], [ 0, -1,  0], [ 0,  0,  1]],
	[[-1,  0,  0], [ 0,  0, -1], [ 0,  1,  0]],
	[[ 0, -1,  0], [-1,  0,  0], [ 0,  0,  1]],
	[[ 0, -1,  0], [ 0,  0, -1], [ 1,  0,  0]],
	[[ 0,  0, -1], [-1,  0,  0], [ 0,  1,  0]],
	[[ 0,  0, -1], [ 0, -1,  0], [ 1,  0,  0]],

	[[-1,  0,  0], [ 0, -1,  0], [ 0,  0, -1]],
	[[-1,  0,  0], [ 0,  0, -1], [ 0, -1,  0]],
	[[ 0, -1,  0], [-1,  0,  0], [ 0,  0, -1]],
	[[ 0, -1,  0], [ 0,  0, -1], [-1,  0,  0]],
	[[ 0,  0, -1], [-1,  0,  0], [ 0, -1,  0]],
	[[ 0,  0, -1], [ 0, -1,  0], [-1,  0,  0]],

];

vec3i mul(vec3i lhs, Matrix rhs) {
	vec3i result;
	result.val[] = [
		lhs.val[0] * rhs[0][0] + lhs.val[1] * rhs[1][0] + lhs.val[2] * rhs[2][0],
		lhs.val[0] * rhs[0][1] + lhs.val[1] * rhs[1][1] + lhs.val[2] * rhs[2][1],
		lhs.val[0] * rhs[0][2] + lhs.val[1] * rhs[1][2] + lhs.val[2] * rhs[2][2],
	];
	return result;
}

alias Scanner = vec3i[];

Scanner normalize(const ref Scanner scanner, Matrix orientation, vec3i translation) {
	Scanner result;
	foreach(beacon; scanner) {
		auto normalized = mul(beacon, orientation) + translation;
		result ~= normalized;
	}
	return result;
}

struct Match {
	bool found;
	vec3i translation = vec3i(0);
	Matrix orientation;
}

Match tryMatch(const ref Scanner scannerA, const ref Scanner scannerB) {
	foreach(orientation; orientations) {
		int[vec3i] deltaCounts;
		foreach(vec3i a; scannerA) {
			foreach(vec3i b; scannerB) {
				vec3i translation = a - mul(b, orientation);
				deltaCounts[translation]++;
				if (deltaCounts[translation] >= 12) {
					return Match(true, translation, orientation);
				}
			}
		}
	}
	return Match(false);
}

Scanner[] parse(string fname) {
	string[] lines = readLines(fname);
	Scanner[] result = [];

	foreach(string[] beaconData; lines.split([""])) {
		Scanner scanner;
		foreach(string beaconStr; beaconData[1..$]) {
			int[] coords = beaconStr.split(",").map!(to!int).array;
			scanner ~= vec3i(coords[0], coords[1], coords[2]);
		}
		result ~= scanner;
	}
	return result;
}

auto solve (string fname) {
	Scanner[] scanners = parse(fname);
	
	bool[int] isNormalized = [ 0: true ];
	vec3i[] scannerLocations = [ vec3i(0) ];
	
	Scanner[] normalized = scanners[0..0];

	// keep adding to the normalized set until everything is added
	while (isNormalized.length < scanners.length) {

		// try a match between every normalized and every non-normalized
		foreach(int i; isNormalized.keys) {
			
			for (int j = 0; j < scanners.length; ++j) {
				if (i == j) continue;
				if (j in isNormalized) continue;

				Match match = tryMatch(scanners[i], scanners[j]);

				if (match.found) {
					writeln(i, " ", j, " matches at ", match.translation, " ", match.orientation);
					isNormalized[j] = true;
					scannerLocations ~= match.translation;

					// replace with normalized
					scanners[j] = normalize(scanners[j], match.orientation, match.translation);
				}
			}
		}
	}

	// flatten, sort and uniq
	vec3i[] beacons = [];
	foreach(scanner; scanners) {
		beacons ~= scanner;
	}
	sort(beacons);
	beacons = uniq(beacons).array;

	// calculate maximum distance between scanners
	int maxDist = 0;
	for(int i = 0; i < scannerLocations.length; ++i) {
		for(int j = i + 1; j < scannerLocations.length; ++j) {
			vec3i delta = scannerLocations[j] - scannerLocations[i]; 
			int dist = abs(delta.x) + abs(delta.y) + abs(delta.z);
			if (dist > maxDist) maxDist = dist;
		}
	}
	return [ beacons.length, maxDist ];
}

void main() {
	Scanner[] scanners = parse("test");

	vec3i translation = vec3i(68, -1246, -43);
	vec3i a = vec3i(-618,-824,-621);
	vec3i b = vec3i(686,422,578);
	Matrix orientation = [[ -1,  0,  0], [ 0,  1,  0], [ 0,  0,  -1]];
	
	assert (mul(a - translation, orientation) == b);
	assert (a - mul(b, orientation) == translation);	
	assert (mul(b, orientation) + translation == a);
	
	Match match_0_1 = tryMatch(scanners[0], scanners[1]);
	assert(match_0_1.found);
	assert(match_0_1.translation == translation);
	assert(match_0_1.orientation == orientation);

	Scanner norm1 = normalize(scanners[1], orientation, translation);
	assert(norm1.canFind(vec3i(459,-707,401)));
	assert(norm1.canFind(vec3i(-739,-1745,668)));
	
	// this point matches between norm1 and scanners[4]
	vec3i a2 = vec3i(534, -1912, 768);
	vec3i b2 = vec3i(-293, -554, 779);
	assert(norm1.canFind(a2));
	assert(scanners[4].canFind(b2));
	vec3i translation3 = vec3i(-20, -1133, 1061);
	Matrix orientation3 = [[0, 0, 1], [-1, 0, 0], [0, -1, 0]];
	assert(a2 - mul(b2, orientation3) == translation3);
	Match match_1_4 = tryMatch(norm1, scanners[4]);
	assert (match_1_4.found);
	assert (match_1_4.translation == translation3);
	assert (match_1_4.orientation == orientation3);
	
	assert (solve("test") == [ 79, 3621 ]);
	writeln (solve("input")); // [326, 10630]
}
