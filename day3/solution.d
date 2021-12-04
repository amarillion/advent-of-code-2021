#!/usr/bin/env -S rdmd -unittest -I..

import common.io;
import std.stdio;
import std.string;
import std.conv;
import std.algorithm;
import std.array;

char compareOnes(string opCmp)(const string bits) {
	size_t ones = bits.count!(s => s == '1');
	size_t zeroes = bits.length - ones;
	return (mixin("ones" ~ opCmp ~ "zeroes")) ? '1' : '0';
}
alias BitSelectorFunc = char function(const string);

int part1Rating(const string[] data, BitSelectorFunc selectBit) {
	string result = "";
	for (int pos = 0; pos < data[0].length; ++pos) {
		string bits = data.map!(s => s[pos]).array;
		result ~= selectBit(bits);
	}
	return to!int(result, 2);
}

int part1(const string[] data) {
	int gamma = part1Rating(data, &compareOnes!">");
	int epsilon = part1Rating(data, &compareOnes!"<");
	return gamma * epsilon;
}

int part2Rating(const string[] original, BitSelectorFunc selectBit) {
	string[] data = original.dup; 
	int pos = 0;
	while (data.length > 1) {
		string bits = data.map!(s => s[pos]).array;
		char toKeep = selectBit(bits);
		data = data.filter!(s => s[pos] == toKeep).array;
		pos++;
	}
	int dataNum = to!int(data[0], 2);
	return dataNum;
}

int part2(const string[] original) {
	int oxygen = part2Rating(original, &compareOnes!">=");
	int co2 = part2Rating(original, &compareOnes!"<");
	return co2 * oxygen;
}

auto run(string fname) {	
	string[] data = readLines(fname);
	return [ part1(data), part2(data) ];
}

void main() {	
	assert(run("test") == [198, 230]);
	writeln(run("input"));
}
