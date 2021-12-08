#!/usr/bin/env -S rdmd -I..

import common.io;
import common.sparsegrid;
import common.vec;
import std.stdio;
import std.conv;
import std.algorithm;
import std.array;
import std.concurrency;
import std.math;
import std.ascii;

string sortString(string str) {
	dchar[] buffer = to!(dchar[])(str); 
	sort(buffer); 
	return to!string(buffer);
}

auto countSimple(string[] lines) {
	int count = 0;
	foreach(line; lines) {
		string[] parts = line.split(" | ");
		writeln(parts);
		string[] outputs = parts[1].split;
		foreach (output; outputs) {
			if ([2, 3, 4, 7].canFind(output.length)) { count++; }
		}
	}
	return count;
}

auto deduce(string[] lines) {
	int count = 0;
	foreach(line; lines) {
		string[] parts = line.split(" | ");
		writeln(parts);
	
		// strings must be sorted for set difference / intersection algorithms to work.
		string[] samples = parts[0].split.map!(sortString).array;
		string[] outputs = parts[1].split.map!(sortString).array;

		// at this point, each letter can mean everything still
		dchar[] initial = to!(dchar[])("abcdefg");
		dchar[][dchar] deduction = [
			'a': initial.dup,
			'b': initial.dup,
			'c': initial.dup,
			'd': initial.dup,
			'e': initial.dup,
			'f': initial.dup,
			'g': initial.dup,
		];

		void restrictOptions(string observed, string expected) {
			// if a letter is in expected, then all other letters are removed as option.
			foreach (dchar e; expected) {
				deduction[e] = setIntersection(deduction[e], observed).array;
			}
			
			// if a letter is not in expected, then observed letters are removed as option.
			dchar[] notInExpected = setDifference("abcdefg", expected).array;
			foreach (dchar e; notInExpected) {
				deduction[e] = setDifference(deduction[e], observed).array;
			}

			writeln(observed);
			foreach(k, v; deduction) {
				writeln (k, " is (one of) ", v);
			}
		}

		void guess(string observed, string[] expected) {
			dchar[] notInObserved  = setDifference("abcdefg", observed).array;

			bool[dchar] missingExpected;
			foreach(m; notInObserved) {
				foreach(k, v; deduction) {
					if (v.canFind(m)) {
						missingExpected[k] = true;
					}
				}
			}

			// map missing to possibilities
			
			// which real segment is not fully covered?
			// see if any of expected can fit
			int foundCount = 0;
			string foundMatch;
			foreach (expect; expected) {
				// check that expect has all values of missingExpected;
				foreach(k; missingExpected.keys) {
					if (!expect.canFind(k)) {
						// there is a problem here.
						foundCount++;
						foundMatch = expect;
						break;
					}
				}
			}
			if (foundCount == 1) {
				writeln("Trying ", observed, " as ", foundMatch, " results in ", missingExpected);
				// now eliminate this guess

				restrictOptions(observed, foundMatch);
			}
		}

		// first, restrict options using digits that are identifiable by length
		foreach (sample; samples) {
			switch(sample.length) {
				case 2: restrictOptions(sample, "cf"); break;
				case 4: restrictOptions(sample, "bcdf"); break;
				case 3: restrictOptions(sample, "acf"); break;
				// case 7: guess(sample, "abcdefg"); break; // not so useful here
				default: /* ignore */ break;
			}
		}

		// now, break ties using the remaining digits.
		foreach (sample; samples) {
			switch(sample.length) {
				case 5: guess(sample, ["acdeg", "abdfg", "acdfg"]); break;
				case 6: guess(sample, ["abcdfg", "abdefg", "abcefg"]); break;
				default: /* ignore */ break;
			}
		}

		// now deduce a singular mapping
		dchar[dchar] finalMapping;
		foreach(k, v; deduction) {
			finalMapping[v[0]] = k;
		}
		
		int[string] toDigit = [
			"abcefg": 0,
			"cf": 1,
			"acdeg": 2,
			"acdfg": 3,
			"bcdf": 4,
			"abdfg": 5,
			"abdefg": 6,
			"acf": 7,
			"abcdefg": 8,
			"abcdfg": 9
		];

		int result = 0;
		foreach (output; outputs) {
			dchar[] converted = output.map!(x => finalMapping[x]).array;
			sort(converted);
			writeln(output, " -> ", converted, " -> ", toDigit[to!string(converted)]);
			result *= 10;
			result += toDigit[to!string(converted)];
		}
		count += result;
	}
	return count;
}

auto solve (string fname) {
	string[] lines = readLines(fname);
	return [
		countSimple(lines), deduce(lines)
	];
}

void main() {
	// writeln (solve("test2"));
	assert (solve("test") == [ 26, 61229 ]);
	writeln (solve("input"));
}
