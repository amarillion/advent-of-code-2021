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
import std.format;

struct Result {
	ulong result;
	int versionSum;
}

final class Parser {
	
	static parse(string hex) {
		auto p = new Parser(hex);
		return Result(p.result, p.versionSum);
	}

	private this(string hex) {
		bits = hex.chunks(1).map!(s => format!"%04b"(to!int(s, 16))).array.join("");
		result = parsePacket();
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
		// writefln("Read literal %s", val);
		return val;
	}

	ulong[] parseOperator() {
		ulong[] subpackets;
		bool id = takeBitAsBool();
		if (id) {
			int numSubPackets = takeBitsAsInt(11);
			// writefln("Expect %s subpackets", numSubPackets);
			foreach (i; 0..numSubPackets) {
				subpackets ~= parsePacket();
			}
		}
		else {
			int numBits = takeBitsAsInt(15);
			size_t expectedRemain = bits.length - numBits;
			// writefln("Expect %s bits of subpackets, with %s bits remaining", numBits, expectedRemain);
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
		// writefln("Packet version %s type %s", ver, type);
		
		if (type == 4) { return parseLiteral(); }
		
		ulong[] data = parseOperator();
		switch(type) {
			case 0: return data.sum();
			case 1: return reduce!((a, b) => a * b)(1L, data);
			case 2: return minElement(data);
			case 3: return maxElement(data);
			case 5: return data[0] > data[1] ? 1 : 0;
			case 6: return data[0] < data[1] ? 1 : 0;
			case 7: return data[0] == data[1] ? 1 : 0;
			default: assert(0);
		}
	}
}

auto solve(string fname) {
	string line = readLines(fname)[0];
	auto data = Parser.parse(line);
	return [ data.versionSum, data.result ];
}

auto calc(string line) {
	return Parser.parse(line).result;
}

auto versionSum(string line) {
	return Parser.parse(line).versionSum;
}

void main() {
	assert (to!int("F", 16) == 15);
	assert (to!string(to!int("F", 16), 2) == "1111");

	assert (versionSum("D2FE28") == 6);
	assert (versionSum("8A004A801A8002F478") == 16);
	assert (versionSum("620080001611562C8802118E34") == 12);
	assert (versionSum("C0015000016115A2E0802F182340") == 23);
	assert (versionSum("A0016C880162017C3686B18A3D4780") == 31);

	assert (calc("C200B40A82") == 3);
	assert (calc("04005AC33890") == 54);
	assert (calc("880086C3E88112") == 7);
	assert (calc("CE00C43D881120") == 9);
	assert (calc("D8005AC2A8F0") == 1);
	assert (calc("F600BC2D8F") == 0);
	assert (calc("9C005AC2F8F0") == 0);
	assert (calc("9C0141080250320F1802104A08") == 1);
	
	writeln (solve("input"));
}
