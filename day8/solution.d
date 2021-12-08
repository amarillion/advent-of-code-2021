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

auto countSimple(string[] lines) {
	int count = 0;
	foreach(line; lines) {
		string[] parts = line.split(" | ");
		writeln(parts);
		string[] samples = parts[0].split;
		string[] outputs = parts[1].split;

		foreach (output; outputs) {
			switch(output.length) {
				case 2: case 4: case 3: case 7: count++; break;
				default: /* ignore */ break;
			}
		}
	}
	return count;
}

auto deduce(string[] lines) {
	int count = 0;
	foreach(line; lines) {
		string[] parts = line.split(" | ");
		writeln(parts);
		string[] samples = parts[0].split;
		string[] outputs = parts[1].split;

		// at this point, each letter can mean everything still
		bool[char] initial = [ 'a': true, 'b': true, 'c': true, 'd': true, 'e': true, 'f': true, 'g': true ];
		bool[char][char] deduction = [
			'a': initial.dup,
			'b': initial.dup,
			'c': initial.dup,
			'd': initial.dup,
			'e': initial.dup,
			'f': initial.dup,
			'g': initial.dup,
		];

		void guess(string observed, string expected) {
			// observed lowercase, expected uppercase
			foreach (char e; "abcdefg") {
				
				bool mustBeThere = !expected.canFind(e);

				foreach(k, ref v; deduction[e]) {
					if (observed.canFind(k) == mustBeThere) {
						if (v) v = false;
					}
				}	
			}
		}

		void guess2(string observed, string[] expected) {
			string missing = "";
			bool[char] missingExpected;
			foreach(i; "abcdefg") {
				if (!observed.canFind(i)) {
					missing ~= i;
				}
			}

			foreach(m; missing) {
				foreach(k, v; deduction) {
					if (v[m]) {
						missingExpected[k] = true;
					}
				}
			}
			// map missing to possibilities
			
			// which real segment of cagedb is not fully covered?
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

				guess(observed, foundMatch);
			}
		}

		foreach (sample; samples) {
			switch(sample.length) {
				case 2: guess(sample, "cf"); break;
				case 4: guess(sample, "bcdf"); break;
				case 3: guess(sample, "acf"); break;
				// case 7: guess(sample, "abcdefg"); break; // not so useful here
				default: /* ignore */ break;
			}

			writeln(sample);
			foreach(k, v; deduction) {
				string d = "";
				foreach(a, b; v) {
					if (b) d ~= a;
				}
				writeln (k, " ", d);
			}
		}

		foreach (sample; samples) {
			switch(sample.length) {
				case 5: guess2(sample, ["acdeg", "abdfg", "acdfg"]); break;
				case 6: guess2(sample, ["abcdfg", "abdefg", "abcefg"]); break;
				default: /* ignore */ break;
			}

			writeln(sample);
			foreach(k, v; deduction) {
				string d = "";
				foreach(a, b; v) {
					if (b) d ~= a;
				}
				writeln (k, " ", d);
			}
		}

		// now deduce a singular mapping
		char[char] finalMapping;
		foreach(k, v; deduction) {
			foreach(a, b; v) {
				if (b) finalMapping[a] = k;
			}
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
			dchar[] converted = output.map!(x => dchar(finalMapping[to!char(x)])).array;
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

	int count = countSimple(lines);

	return [
		count, deduce(lines)
	];
}

void main() {
	assert (solve("test") == [ 26, 61229 ]);
	writeln (solve("input"));
}
