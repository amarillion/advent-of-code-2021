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

final class Parser {
	
	this(string hex) {
		bits = hex.map!(ch => hex2bin[to!char(ch)]).array.join("");
		parse();
	}

	string bits;
	int versionSum;
	ulong result;

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

	ulong parseLiteral() {
		ulong val = 0;
		while (takeBitAsBool()) {
			val *= 16;
			val += takeBitsAsInt(4); 
		}
		val *= 16;
		val += takeBitsAsInt(4);
		writefln("Read literal %s", val);
		return val;
	}

	ulong[] parseOperator() {
		ulong[] subpackets;
		bool id = takeBitAsBool();
		if (id) {
			// number of subpackets
			int numSubPackets = takeBitsAsInt(11);
			writefln("Expect %s subpackets", numSubPackets);
			foreach (i; 0..numSubPackets) {
				subpackets ~= parsePacket();
			}
		}
		else {
			// number of bits in subpackets...
			int numBits = takeBitsAsInt(15);
			size_t expectedRemain = bits.length - numBits;
			writefln("Expect %s bits of subpackets, with %s bits remaining", numBits, expectedRemain);
			while (bits.length > expectedRemain) {
				subpackets ~= parsePacket();
			}
		}
		return subpackets;
	}

	ulong parsePacket() {
		int ver = takeBitsAsInt(3);
		int type = takeBitsAsInt(3);
		versionSum += ver;
		writefln("Packet version %s type %s", ver, type);
		if (type == 4) {
			return parseLiteral();
		}
		
		ulong[] data = parseOperator();
		switch(type) {
			case 0:
				return data.sum();
			case 1:
				return reduce!((a, b) => a * b)(1L, data);
			case 2:
				return minElement(data);
			case 3:
				return maxElement(data);
			case 5:
				return data[0] > data[1] ? 1 : 0;
			case 6:
				return data[0] < data[1] ? 1 : 0;
			case 7:
				return data[0] == data[1] ? 1 : 0;
			default: assert(0);
		}
	}

	void parse() {
		// reading a packet...
		while (bits.length >= 8) {
			result = parsePacket();
			// NB: if there are multiple packets, only last value is used...
		}
	}
}

auto readAndSolve(string fname) {
	string line = readLines(fname)[0];
	Parser parser = new Parser(line);
	return [ parser.versionSum, parser.result ];
}

auto calc(string line) {
	return new Parser(line).result;
}

auto getSumVersions(string line) {
	return new Parser(line).versionSum;
}

void main() {
	assert (getSumVersions("D2FE28") == 6);
	assert (getSumVersions("8A004A801A8002F478") == 16);
	assert (getSumVersions("620080001611562C8802118E34") == 12);
	assert (getSumVersions("C0015000016115A2E0802F182340") == 23);
	assert (getSumVersions("A0016C880162017C3686B18A3D4780") == 31);

	assert (calc("C200B40A82") == 3);
	assert (calc("04005AC33890") == 54);
	assert (calc("880086C3E88112") == 7);
	assert (calc("CE00C43D881120") == 9);
	assert (calc("D8005AC2A8F0") == 1);
	assert (calc("F600BC2D8F") == 0);
	assert (calc("9C005AC2F8F0") == 0);
	assert (calc("9C0141080250320F1802104A08") == 1);
	
	writeln (readAndSolve("input"));
}
