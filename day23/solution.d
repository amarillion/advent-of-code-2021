#!/usr/bin/env -S rdmd -g -I..

import common.io;
import common.vec;
import std.stdio;
import std.conv;
import std.algorithm;
import std.array;
import std.concurrency;
import std.math;
import std.range;
import std.typecons;
import common.util;
import common.grid;
import common.coordrange;
import std.container.binaryheap;

struct Step(N, E) {
	N src;
	E edge;
	N dest;
	int cost;
}

auto astar(N, E)(
	N source, 
	N dest, 
	Tuple!(E, N)[] delegate(N) getAdjacent, 
	int delegate(Tuple!(E, N)) getWeight,
	int delegate(N) getHeuristic = (N) => 0,
	int maxIterations = -1
) {
	int[N] dist = [ source: 0 ];
	int[N] priority = [ source: 0 ];
	Step!(N, E)[N] prev;

	// priority queue	
	auto open = heapify!((a, b) => priority[a] > priority[b])([ source ]);

	int i = maxIterations;
	while (open.length > 0) {
		N current = open.front;
		open.popFront;
		
		// check adjacents, calculate distance, or  - if it already had one - check if new path is shorter
		foreach(Tuple!(E, N) adj; getAdjacent(current)) {
			N sibling = adj[1];
			E edge = adj[0];
			const cost = dist[current] + getWeight(adj);
			const oldCost = sibling in dist ? dist[sibling] : int.max;

			if (cost < oldCost) {
				dist[sibling] = cost;
				priority[sibling] = cost + getHeuristic(sibling);
				open.insert(sibling);
				
				// build back-tracking map
				prev[sibling] = Step!(N, E)(current, edge, sibling, cost);
			}
		}

		if (current == dest) {
			break;	
		}

		i--; // 0 -> -1 means Infinite.
		if (i == 0) break;
		if (i % 10000 == 0) { writeln(-i, " ", open.length); }
	}

	return prev;
}

enum char[int] hallTarget = [
	11: 'A',
	12: 'A',
	13: 'A',
	14: 'A',
	15: 'B',
	16: 'B',
	17: 'B',
	18: 'B',
	19: 'C',
	20: 'C',
	21: 'C',
	22: 'C',
	23: 'D',
	24: 'D',
	25: 'D',
	26: 'D',
];
enum int[char] podCosts = [
	'A': 1, 'B': 10, 'C': 100, 'D': 1000
];
int[][] hallAdj = [
	/* 0 */ [ 1 ], 
	/* 1 */ [ 0, 2 ], 
	/* 2 */ [ 1, 3, 11 ], 
	/* 3 */ [ 2, 4 ], 
	/* 4 */ [ 3, 5, 15 ], 
	/* 5 */ [ 4, 6 ], 
	/* 6 */ [ 5, 7, 19 ], 
	/* 7 */ [ 6, 8 ], 
	/* 8 */ [ 7, 9, 23 ], 
	/* 9 */ [ 8, 10 ], 
	/*10 */ [ 9 ], 
	/*11 */ [ 2, 12 ], 
	/*12 */ [ 11, 13 ], 
	/*13 */ [ 12, 14 ], 
	/*14 */ [ 13 ], 
	/*15 */ [ 4, 16 ], 
	/*16 */ [ 15, 17 ], 
	/*17 */ [ 16, 18 ], 
	/*18 */ [ 17 ], 
	/*19 */ [ 6, 20 ], 
	/*20 */ [ 19, 21 ], 
	/*21 */ [ 20, 22 ], 
	/*22 */ [ 21 ], 
	/*23 */ [ 8, 24 ], 
	/*24 */ [ 23, 25 ], 
	/*25 */ [ 24, 26 ], 
	/*26 */ [ 25 ], 
];
enum Point[int] podPoints = [ 
	11: Point(3,2), 12: Point(3,3), 13: Point(3,4), 14: Point(3,5), 
	15: Point(5,2), 16: Point(5,3), 17: Point(5,4), 18: Point(5,5),
	19: Point(7,2), 20: Point(7,3), 21: Point(7,4), 22: Point(7,5), 
	23: Point(9,2), 24: Point(9,3), 25: Point(9,4), 26: Point(9,5),
];

struct Pod {
	char type;
	int pos;

	this(char type, int pos) {
		assert(['A', 'B', 'C', 'D'].canFind(type), "Wrong type " ~ type);
		this.type = type;
		this.pos = pos;
	}
}

struct Move {
	int cost;
	Pod from;
	int to;
}

struct State {
	Pod[16] pods;
}

void sortPods(ref State state) {
	sort!((a, b) => a.pos < b.pos)(state.pods[]);
}

alias Edge = Tuple!(Move, State);

bool isEndCondition(State state) {
	foreach(Pod p; state.pods) {
		if (p.pos !in hallTarget) return false;
		if (hallTarget[p.pos] != p.type) return false;
	}
	return true;
}

bool targetRoomMismatch(State state, int type) {
	foreach(p; state.pods) {
		// for all the pods that are in a room
		if (p.pos !in hallTarget) continue;
		// for all the pods that are in the room of the target type
		if (hallTarget[p.pos] != type) continue;
		
		// is that pod of the right type?
		if (p.type != type) return false;
	}
	return true;
}

enum int[][char] heuristicData = [
	'A': [ 3, 2, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 0, 0, 0, 4, 5, 6, 7, 6, 7, 8, 9, 8, 9,10,11 ],
	'B': [ 5, 4, 3, 2, 1, 2, 3, 4, 5, 6, 7, 4, 5, 6, 7, 0, 0, 0, 0, 4, 5, 6, 7, 6, 7, 8, 9 ],
	'C': [ 7, 6, 5, 4, 3, 2, 1, 2, 3, 4, 5, 6, 7, 8, 9, 4, 5, 6, 7, 0, 0, 0, 0, 4, 5, 6, 7 ],
	'D': [ 9, 8, 7, 6, 5, 4, 3, 2, 1, 2, 3, 8, 9,10,11, 6, 7, 8, 9, 4, 5, 6, 7, 0, 0, 0, 0 ]
];

// calculate cost of putting everyting in its right state...
int heuristic(State state) {
	int result = 0;
	foreach(pod; state.pods) {
		result += heuristicData[pod.type][pod.pos] * podCosts[pod.type];
	}
	return result;
}

Edge[] validMoves(State state) {
	Edge[] result;
	// create a position map
	char[int] occupancy;
	foreach (Pod p; state.pods) {
		occupancy[p.pos] = p.type;
	}

	foreach (int ii, Pod p; state.pods) {

		Tuple!(int, int)[] adjFunc(int i) {
			return hallAdj[i].filter!(j => j !in occupancy).map!(i => tuple(0, i)).array;
		}
		
		// calculate cost for all Edges where this can go...
		auto astarResult = astar!(int, int)(p.pos, -1, &adjFunc, (Tuple!(int,int)) => podCosts[p.type]);

		foreach(dest; astarResult.keys) {
			State newState = state;
			newState.pods[ii] = Pod(p.type, dest);
			sortPods(newState);

			// never stop on t-section
			if (hallAdj[dest].length == 3) continue;
			// don't move within hallway
			if (p.pos <= 10 && dest <= 10) continue;
			// don't move to room unless it's the destination
			if (dest >= 11 && hallTarget[dest] != p.type) continue;
			// destination must not contain mismatches.
			if (dest >= 11 && !targetRoomMismatch(newState, p.type)) continue;
			// EXTRA CONDITION to reduce search space: don't move within a room
			if (p.pos >= 11 && dest >= 11 && hallTarget[p.pos] == hallTarget[dest]) continue;
			// EXTRA CONDITION to reduce search space: if we're in a room, check that the next spot isn't empty
			if (dest >= 11 && ((dest-11) % 4 < 3) && ((dest + 1) !in occupancy)) continue;
			
			int cost = astarResult[dest].cost;
			result ~= tuple(Move(cost, p, dest), newState);
		}
	}
	return result;
}

void checkMoves(State state) {
	Edge[] moves;
	bool[State] visited;

	void processMoves() {
		foreach (move; moves) {
			writefln("Can move %s to %s with cost %s. Visited: %s, Heuristic %s", 
				move[0].from, move[0].to, move[0].cost, move[1] in visited ? "true" : "false",
				heuristic(move[1]));
			visited[move[1]] = true;
		}
	}

	writeln("step 1");
	moves = validMoves(state);
	processMoves();
	foreach (i; 2..3) {
		writefln("Step %s", i);
		moves = moves.filter!(m => m[1] in visited).array;
		moves = moves
			.map!(m => validMoves(m[1]))
			.join
			.array;
		processMoves();
	}
}

auto solve (string fname) {
	string[] lines = readLines(fname);
	
	Point size = Point(to!int(lines[0].length), to!int(lines.length));
	
	Grid!char grid = new Grid!char(size.x, size.y);
	foreach(pos; PointRange(grid.size)) {
		string line = lines[pos.y];
		char ch = pos.x < line.length ? line[pos.x] : '.';
		grid.set(pos, ch);
	}

	Pod[] pods = [];
	foreach(hallPos, v; podPoints) {
		pods ~= Pod(grid.get(v), hallPos);
		grid.set(v, '.');
	}
	State state = State(to!(Pod[16])(pods));
	sortPods(state);
	
	// checkMoves(state);
	State goal = State([
		Pod('A', 11), Pod('A', 12), Pod('A', 13), Pod('A', 14), 
		Pod('B', 15), Pod('B', 16), Pod('B', 17), Pod('B', 18),
		Pod('C', 19), Pod('C', 20), Pod('C', 21), Pod('C', 22), 
		Pod('D', 23), Pod('D', 24), Pod('D', 25), Pod('D', 26),
	]);
	assert(goal.isEndCondition);

	auto astarResult = astar!(State, Move)(
		state, 
		goal, 
		s => s.validMoves, 
		(Edge m) => m[0].cost,
		s => s.heuristic
	);
	auto current = goal;
	assert(current in astarResult);
	return [ astarResult[goal].cost ];
}

void main() {
	assert (solve("test") == [ 44169 ]);
	writeln (solve("input"));
}
