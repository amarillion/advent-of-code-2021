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

/** scale up */
vec3i mul(vec3i lhs, Matrix rhs) {
	vec3i result;
	result.val[] = [
		lhs.val[0] * rhs[0][0] + lhs.val[1] * rhs[1][0] + lhs.val[2] * rhs[2][0],
		lhs.val[0] * rhs[0][1] + lhs.val[1] * rhs[1][1] + lhs.val[2] * rhs[2][1],
		lhs.val[0] * rhs[0][2] + lhs.val[1] * rhs[1][2] + lhs.val[2] * rhs[2][2],
	];
	return result;
}

Matrix mul(Matrix lhs, Matrix rhs) {
	Matrix result;
	result = [
		[
			lhs[0][0] * rhs[0][0] + lhs[0][1] * rhs[1][0] + lhs[0][2] * rhs[2][0],
			lhs[0][0] * rhs[0][1] + lhs[0][1] * rhs[1][1] + lhs[0][2] * rhs[2][1],
			lhs[0][0] * rhs[0][2] + lhs[0][1] * rhs[1][2] + lhs[0][2] * rhs[2][2],
		], [
			lhs[1][0] * rhs[0][0] + lhs[1][1] * rhs[1][0] + lhs[1][2] * rhs[2][0],
			lhs[1][0] * rhs[0][1] + lhs[1][1] * rhs[1][1] + lhs[1][2] * rhs[2][1],
			lhs[1][0] * rhs[0][2] + lhs[1][1] * rhs[1][2] + lhs[1][2] * rhs[2][2],
		], [
			lhs[2][0] * rhs[0][0] + lhs[2][1] * rhs[1][0] + lhs[2][2] * rhs[2][0],
			lhs[2][0] * rhs[0][1] + lhs[2][1] * rhs[1][1] + lhs[2][2] * rhs[2][1],
			lhs[2][0] * rhs[0][2] + lhs[2][1] * rhs[1][2] + lhs[2][2] * rhs[2][2],
		]
	];
	return result;
}

alias Scanner = bool[vec3i];

struct Facing {
	vec3i translation;
	Matrix orientation;
}

int countMatches(const ref Scanner scannerA, const ref Scanner scannerB, Matrix orientation, vec3i translation) {
	int count = 0;
	foreach(vec3i a; scannerA.keys) {
		if ((mul(a - translation, orientation)) in scannerB) {
			count++;
		}
	}
	return count;
}

Scanner normalize(const ref Scanner scanner, Matrix orientation, vec3i translation) {
	Scanner result;
	foreach(vec3i beacon; scanner.keys) {
		auto nb = mul(beacon, orientation) + translation;
		result[nb] = true;
	}
	return result;
}

struct Match {
	bool found;
	vec3i translation = vec3i(0);
	Matrix orientation;
}

Match tryMatch(const ref Scanner scannerA, const ref Scanner scannerB, Matrix baseOrientation = orientations[0], 
	vec3i baseTranslation = vec3i(0)
) {
	// set translation to first beacon.
	foreach(vec3i a; scannerA.keys) {
		foreach(vec3i b; scannerB.keys) {
			foreach(orientation; orientations) {
				// -20,-1133,1061
				vec3i translation = a - mul(b, orientation);
				int count = countMatches(scannerA, scannerB, orientation, translation);
				if (count >= 12) {
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

	// read beacons
	foreach(string[] beaconData; lines.split([""])) {
		Scanner scanner;
		foreach(string beaconStr; beaconData[1..$]) {
			int[] coords = beaconStr.split(",").map!(to!int).array;
			scanner[vec3i(coords[0], coords[1], coords[2])] = true;
		}
		result ~= scanner;
	}
	return result;
}

auto solve (string fname) {
	Scanner[] scanners = parse(fname);
	// now try to position scanners one by one.
	// we're trying to find a translation vector for scanner 0.
	
	int linked = 1;
	Match[] normalized;
	normalized.length = scanners.length;
	normalized[0] = Match(true, vec3i(0), orientations[0]);

	vec3i[] beacons = [];

	// while (linked < scanners.length) {
		for(int i = 0; i < scanners.length; ++i) {
			if (!normalized[i].found) continue;

			for (int j = 0; j < scanners.length; ++j) {
				if (i == j) continue;
				if (normalized[j].found) continue;

				Match match = tryMatch(scanners[i], scanners[j], normalized[i].orientation, normalized[i].translation);

				if (match.found) {
					writeln(i, " ", j, " matches at ", match.translation, " ", match.orientation);
					normalized[j] = match;

					Scanner norm = normalize(scanners[j], match.orientation, match.translation);
					foreach(n; norm.keys) {
						beacons ~= n;
					}

					break;
				}

			}

		}

	// }

	
	sort(beacons);
	beacons = uniq(beacons).array;

	writeln(beacons);

	return [ beacons.length ];
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

	assert (countMatches(scanners[0], scanners[1], orientation, translation) >= 12);
	
	Match match_0_1 = tryMatch(scanners[0], scanners[1]);
	assert(match_0_1.found);
	assert(match_0_1.translation == translation);
	assert(match_0_1.orientation == orientation);

	Scanner norm1 = normalize(scanners[1], orientation, translation);
	assert(vec3i(459,-707,401) in norm1);
	assert(vec3i(-739,-1745,668) in norm1);
	
	Matrix orientation2 = [[0, -1, 0], [0, 0, -1], [1, 0, 0]];
	vec3i translation2 = vec3i(-20,-1133,1061);
	assert (countMatches(norm1, scanners[4], orientation2, translation2) >= 12);
	
	// foreach (o; orientations) {
	// 	writefln ("%s %s", o, countMatches(norm1, scanners[4], o, );
	// }

	Match match_1_4 = tryMatch(norm1, scanners[4]); 
	// writeln(norm4.keys);
	// Match match_1_4 = tryMatch(scanners[1], scanners[4], orientation, translation); 
	// writeln(match_1_4);
	// assert (match_1_4.found);
	
	assert (solve("test") == [ 79 ]);
	writeln (solve("input"));
}
