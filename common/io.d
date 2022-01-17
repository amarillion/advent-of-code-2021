module common.io;

import std.file;
import std.string;

string[] readLines(string fname) {
	string[] result = readText(fname).stripRight.split('\n');
	return result;
}
