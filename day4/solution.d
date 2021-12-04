#!/usr/bin/env -S rdmd -unittest -I..

import common.io;
import std.stdio;
import std.string;
import std.conv;
import std.algorithm;
import std.array;

int[] fiveInts(string line) {
	int[] result = [];
	for (int i = 0; i < 5; ++i) {
		string val = line[i*3..(i*3)+2].strip();
		result ~= to!int(val);
	}
	return result;
}
void main() {	
	string[] data = readLines("input");
	int[] numbers = data[0].split(",").map!(to!int).array;
	writeln(numbers);
	
	int [][][] boards = [];

	for (int i = 2; i < data.length; i += 6) {
		int[][] board = data[i..i+5].map!(line => fiveInts(line)).array;
		boards ~= board;
	}

	foreach (int number; numbers) {
		// find on board, replace with 0;

		foreach (int[][] board; boards) {
			foreach (int[] row; board) {
				foreach (ref int cell; row) {
					if (cell == number) cell = 0;
				}
			}
		}

		// check boards for winners
		bool found = false;
		int[][] winningBoard;
		foreach (int[][] board; boards) {
			foreach(int[] row; board) {
				if (row.sum() == 0) {
					found = true;
					winningBoard = board;
					break;
				}
			}

			for (int y = 0; y < 5; ++y) {
				if (board.map!(row => row[y]).sum() == 0) {
					found = true;
					winningBoard = board;
					break;
				}
			}

			if (found) {
				break;
			}
		}

		if (found) {
			writeln("Winning board: ", winningBoard);
			int totalSum = winningBoard.map!(row => row.sum()).sum();

			writeln(totalSum, " ", number, " ", totalSum * number);
			break;
		}
	}



}
