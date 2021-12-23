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

alias DijkstraResult(N, E) = Step!(N,E)[N];

auto dijkstra(N, E)(
	N source, 
	N dest, 
	Tuple!(E, N)[] delegate(N) getAdjacent, 
	int delegate(Tuple!(E, N)) getWeight,
	int delegate(N) getHeuristic = (N) => 0,
	int maxIterations = -1
) {
	int[N] dist = [ source: 0 ];
	int[N] priority = [ source: 0 ];
	bool[N] visited;
	Step!(N, E)[N] prev;
	N goal;
	
	// TODO: more efficient to use a priority queue here
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

		// A visited node will never be checked again.
		visited[current] = true;

		if (current == dest) {
			break;	
		}

		i--; // 0 -> -1 means Infinite.
		if (i == 0) break;

		if (i % 10000 == 0) { writeln(i); }
	}

	return prev;
}

/*
#############
#...........#
###D#D#B#A###
  #B#C#A#C#
  #########
*/

enum bool[int] hallDisallowed = [
	2: true, 4: true, 6: true, 8: true
];
enum char[int] hallTarget = [
	11: 'A',
	12: 'A',
	13: 'B',
	14: 'B',
	15: 'C',
	16: 'C',
	17: 'D',
	18: 'D'
];
enum int[char] podCosts = [
	'A': 1, 'B': 10, 'C': 100, 'D': 1000
];
int[][] hallAdj = [
	/* 0 */ [ 1 ], 
	/* 1 */ [ 0, 2 ], 
	/* 2 */ [ 1, 3, 11 ], 
	/* 3 */ [ 2, 4 ], 
	/* 4 */ [ 3, 5, 13 ], 
	/* 5 */ [ 4, 6 ], 
	/* 6 */ [ 5, 7, 15 ], 
	/* 7 */ [ 6, 8 ], 
	/* 8 */ [ 7, 9, 17 ], 
	/* 9 */ [ 8, 10 ], 
	/*10 */ [ 9 ], 
	/*11 */ [ 2, 12 ], 
	/*12 */ [ 11 ], 
	/*13 */ [ 4, 14 ], 
	/*14 */ [ 13 ], 
	/*15 */ [ 6, 16 ], 
	/*16 */ [ 15 ], 
	/*17 */ [ 8, 18 ], 
	/*18 */ [ 17 ], 
];
enum Point[int] podPoints = [ 
	11: Point(3,2), 12: Point(3,3), 
	13: Point(5,2), 14: Point(5,3), 
	15: Point(7,2), 16: Point(7,3), 
	17: Point(9,2), 18: Point(9,3)
];

struct Pod {
	char type;
	int pos;
}

struct Move {
	int cost;
	Pod from;
	int to;
}

struct State {
	Pod[8] pods;
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
		if (p.pos !in hallTarget) continue;
		if (hallTarget[p.pos] == type) {
			if (p.type != type) return false;
		}
	}
	return true;
}

enum int[][char] heuristicData = [
	'A': [ 3, 2, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 0, 4, 5, 6, 7, 8, 9 ],
	'B': [ 5, 4, 3, 2, 1, 2, 3, 4, 5, 6, 7, 4, 5, 0, 0, 4, 5, 6, 7 ],
	'C': [ 7, 6, 5, 4, 3, 2, 1, 2, 3, 4, 5, 6, 7, 4, 5, 0, 0, 4, 5 ],
	'D': [ 9, 8, 7, 6, 5, 4, 3, 2, 1, 2, 3, 8, 9, 6, 7, 4, 5, 0, 0 ]
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
	foreach (int ii, Pod p; state.pods) {
		
		bool isEmpty(int l) {
			foreach(Pod q; state.pods) {
				if (q.pos == l) return false;
			}
			return true;
		}

		Tuple!(int, int)[] adjFunc(int i) {
			return hallAdj[i].filter!(j => isEmpty(j)).map!(i => tuple(0, i)).array;
		}
		
		// calculate cost for all Edges where this can go...
		auto dijk = dijkstra!(int, int)(p.pos, -1, &adjFunc, (Tuple!(int,int)) => podCosts[p.type]);

		foreach(dest; dijk.keys) {
			State newState = state;
			newState.pods[ii] = Pod(p.type, dest);
			// newState.moves = state.moves + 1;
			sortPods(newState);

			bool valid = true;
			// never stop on space immediately outside room
			if (dest in hallDisallowed) valid = false;
			// don't move within hallway
			if (p.pos <= 10 && dest <= 10) valid = false;
			// don't move to room unless it's the destination
			if (dest >= 11 && hallTarget[dest] != p.type) valid = false;
			// don't move within a room (NOTE: stricter than needed)
			if (p.pos >= 11 && dest >= 11 && hallTarget[p.pos] == hallTarget[dest]) valid = false;
			// extra condition: destination must not be occupied by mismatches
			if (dest >= 11 && !targetRoomMismatch(newState, p.type)) valid = false;
			if (!valid) continue;

			int cost = dijk[dest].cost;
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
	State state = State(to!(Pod[8])(pods));
	writefln("State: %s", state);
	sortPods(state);
	writefln("State: %s", state);
	int minCost = int.max;

	// checkMoves(state);
	State goal = State([
		Pod('A', 11), Pod('A', 12), Pod('B', 13), Pod('B', 14), 
		Pod('C', 15), Pod('C', 16), Pod('D', 17), Pod('D', 18)
	]);
	assert(goal.isEndCondition);

	auto dijkstraResult = dijkstra!(State, Move)(
		state, 
		goal, 
		s => s.validMoves, 
		(Edge m) => m[0].cost,
		s => s.heuristic
	);
	auto current = goal;
	assert(current in dijkstraResult);
	while (current in dijkstraResult) {
		auto step = dijkstraResult[current];
		writeln(step);
		current = step.src;
	}

	return [ dijkstraResult[goal].cost ];
}

void test() {
	auto dist = [1:50, 2:40, 3:30, 4:20, 5:10];
	auto heap = heapify!((a,b) => dist[a] > dist[b])([3]);

	assert(heap.dup.canFind(5) == false);
	
	assert(heap.front == 3);
	heap.insert(4);
	assert(heap.front == 4);
	heap.insert(2);
	assert(heap.front == 4);
	heap.insert(1);
	assert(heap.front == 4);
	heap.insert(5);
	assert(heap.front == 5);

	assert(heap.dup.canFind(5) == true);

	heap.popFront;
	// writeln(heap);
	assert(heap.front == 4);
	heap.popFront;
	assert(heap.front == 3);
	heap.popFront;
	assert(heap.front == 2);
	writeln(heap);

	int[4] ints = [2, 3, 1, 0];
	sort(ints[]);
	assert(ints == [0, 1, 2, 3]);
}

void main() {
	test();
	assert (solve("test") == [ 12521 ]);
	writeln (solve("input"));
}
