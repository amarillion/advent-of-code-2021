module common.io;

import std.stdio;
import std.string;

string[] readLines(string fname) {
	File file = File(fname, "rt");
	string[] result = [];
	while (!file.eof()) {
		string line = chomp(file.readln()); 
		result ~= line;
	}
	// Remove empty line...
	if (result[$-1].length == 0) { result = result[0..$-1]; }
	return result;
}
