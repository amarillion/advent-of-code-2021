#!/usr/bin/env -S rdmd -unittest -I..

import common.io;
import std.stdio;
import std.string;
import std.conv;
import std.algorithm;
import std.array;

char selectedBit(const string bits, bool takeHighest, char tieBreaker = '1') {
	size_t ones = bits.count!(s => s == '1');
	size_t zeroes = bits.length - ones;
	if (ones == zeroes) return tieBreaker;
	return ((ones > zeroes) == takeHighest) ? '1' : '0';
}
alias BitSelectorFunc = char delegate(const string);

int part1Rating(const string[] data, BitSelectorFunc selectBit) {
	string result = "";
	for (int pos = 0; pos < data[0].length; ++pos) {
		string bits = data.map!(s => s[pos]).array;
		result ~= selectBit(bits);
	}
	return to!int(result, 2);
}

int part1(const string[] data) {
	int gamma = part1Rating(data, (bits) => selectedBit(bits, true));
	int epsilon = part1Rating(data, (bits) => selectedBit(bits, false));
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
	int oxygen = part2Rating(original, (bits) => selectedBit(bits, true, '1'));
	int co2 = part2Rating(original, (bits) => selectedBit(bits, false, '0'));
	return co2 * oxygen;
}

void main() {	
	string[] data = readLines("input");
	writeln(part1(data));
	writeln(part2(data));
}
