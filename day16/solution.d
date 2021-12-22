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

enum hex2bin = [
	'0': "0000",
	'1': "0001",
	'2': "0010",
	'3': "0011",
	'4': "0100",
	'5': "0101",
	'6': "0110",
	'7': "0111",
	'8': "1000",
	'9': "1001",
	'A': "1010",
	'B': "1011",
	'C': "1100",
	'D': "1101",
	'E': "1110",
	'F': "1111",
];

class Parser {
	
	this(string initial) {
		bits = initial;
	}

	string bits;
	int versionSum;

	string takeBits(int num) {
		string prefix = bits[0..num];
		bits = bits[num..$];
		return prefix;
	}

	int takeBitsAsInt(int num) {
		string prefix = takeBits(num);
		return to!int(prefix, 2);
	}

	bool takeBitAsBool() {
		string prefix = takeBits(1);
		return prefix == "1";
	}

	int parseLiteral() {
		int val = 0;
		while (takeBitAsBool()) {
			val *= 16;
			val += takeBitsAsInt(4); 
		}
		val *= 16;
		val += takeBitsAsInt(4);
		writefln("Read literal %s", val);
		return val;
	}

	void parseOperator() {
		bool id = takeBitAsBool();
		if (id) {
			// number of subpackets
			int numSubPackets = takeBitsAsInt(11);
			writefln("Expect %s subpackets", numSubPackets);
			foreach (i; 0..numSubPackets) {
				parsePacket();
			}
		}
		else {
			// number of bits in subpackets...
			int numBits = takeBitsAsInt(15);
			size_t expectedRemain = bits.length - numBits;
			writefln("Expect %s bits of subpackets, with %s bits remaining", numBits, expectedRemain);
			while (bits.length > expectedRemain) {
				parsePacket();
			}
		}
	}

	void parsePacket() {
		int ver = takeBitsAsInt(3);
		int type = takeBitsAsInt(3);
		writefln("Packet version %s type %s", ver, type);
		switch(type) {
			case 4:
				parseLiteral(); 
			break;
			default: 
				parseOperator();
				break;
		}
		versionSum += ver;
	}

	int parse() {

		// reading a packet...
		while (bits.length >= 8) {
			parsePacket();
		}

		return versionSum;
	}
}

auto readAndSolve(string fname) {
	string line = readLines(fname)[0];
	return solveHex(line);
}

auto solveHex(string line) {
	string bits = line.map!(ch => hex2bin[to!char(ch)]).array.join("");
	return [ new Parser(bits).parse() ];
}

void main() {
	assert (solveHex("D2FE28") == [ 6 ]);
	assert (solveHex("8A004A801A8002F478") == [ 16 ]);
	assert (solveHex("620080001611562C8802118E34") == [ 12 ]);
	assert (solveHex("C0015000016115A2E0802F182340") == [ 23 ]);
	assert (solveHex("A0016C880162017C3686B18A3D4780") == [ 31 ]);
	writeln (readAndSolve("input"));
}
