#!/usr/bin/env -S rdmd -I..

import common.io;
import std.stdio;
import std.string;
import std.conv;
import std.algorithm;
import std.array;
import std.range;
import std.functional;

alias Board = int[][];
struct Winner {
	Board board;
	int number; // the number that made this board win
}

Board parseBoard(string[] lines) {
	assert(lines.length == 5);
	return lines.map!(line => line.split.map!(to!int).array).array;
}

bool isBingo(Board board) {
	for (int i = 0; i < 5; ++i) {
		if (board[i].sum == 0 || board.transversal(i).sum == 0) {
			return true;
		}
	}
	return false;
}

// find called number on board, replace with 0;
void markNumber(Board board, int number) {
	foreach (int[] row; board) {
		foreach (ref int cell; row) {
			if (cell == number) cell = 0;
		}
	}
}

Winner[] sortedWinners(Board[] boards, int[] numbers) {
	Winner[] winners = [];
	foreach (int number; numbers) {
		foreach (Board board; boards) {
			board.markNumber(number);		
		}

		// add winning boards to winners set		
		winners ~= boards.filter!isBingo.map!(b => Winner(b, number)).array;
		// remove winning boards from play
		boards = boards.filter!(not!isBingo).array;
	}
	return winners;
}

int score(Winner winner) {
	return winner.number * winner.board.map!(row => row.sum()).sum();
}

int[2] firstAndLastScores(string fname) {	
	string[] data = readLines(fname);
	int[] numbers = data[0].split(",").map!(to!int).array;
	
	Board[] boards = [];
	for (int i = 2; i < data.length; i += 6) {
		boards ~= parseBoard(data[i..i+5]);
	}

	Winner[] winners = sortedWinners(boards, numbers);
	return [winners[0].score, winners[$-1].score];
}

void main() {
	assert (firstAndLastScores("test") == [ 4512, 1924 ]);
	writeln (firstAndLastScores("input"));
}
