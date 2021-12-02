#!/usr/bin/env -S rdmd -unittest -I..

import common.io;
import std.stdio;
import std.string;
import std.conv;
import std.algorithm;
import std.array;


int part1(Command[] commands) {
	int x = 0;
	int depth = 0;
	foreach(c; commands) {
		switch(c.direction) {
			case "forward": x += c.amount; break;
			case "down": depth += c.amount; break;
			case "up": depth -= c.amount; break;
			default: assert(0);
		}
	}
	return x * depth;
}

int part2(Command[] commands) {
	int x = 0;
	int depth = 0;
	int aim = 0;
	foreach(c; commands) {
		switch(c.direction) {
			case "forward": x += c.amount; depth += c.amount * aim; break;
			case "down": aim += c.amount; break;
			case "up": aim -= c.amount; break;
			default: assert(0);
		}
	}
	return x * depth;
}

Command[] parseLines(string[] lines) {
	Command[] result = [];
	foreach(line; lines) {
		string[] fields = line.split(" ");
		result ~= Command(fields[0], to!int(fields[1]));
	}
	return result;
}

struct Command {
	string direction;
	int amount;
}

void main() {
	Command[] commands = parseLines(readLines("input"));
	writeln(part1(commands));
	writeln(part2(commands));
}
