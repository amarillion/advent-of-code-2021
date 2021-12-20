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
import common.grid;
import common.coordrange;

auto getAdjacent(const Grid!int grid, const Point pos) {
	Point[] deltas = [
		Point(0, 1), Point(1, 0), Point(0, -1), Point(-1, 0)
	];
	Point[] result = [];
	foreach(delta; deltas) {
		Point np = pos + delta;
		if (!grid.inRange(np)) continue;
		result ~= np;
	}
	return result;
}

int dijkstra(N)(N source, N dest, N[] delegate(N) getAdjacent, int delegate(N) getWeight) {
	// Mark all nodes unvisited. Create a set of all the unvisited nodes called the unvisited set.
	// Assign to every node a tentative distance value: set it to zero for our initial node and to infinity for all other nodes. Set the initial node as current.[13]
	int[N] dist = [ source: 0 ];
	bool[N] visited;
	N[N] prev;
	
	// TODO: more efficient to use a priority queue here
	const(N)[] open = [ source ];


	// int maxIterations = 1000;
	// int i = maxIterations;
	while (open.length > 0) {
		
		// i--; // 0 -> -1 means Infinite.
		// if (i == 0) break;

		// extract the element from Q with the lowest dist. Open is modified in-place.
		// TODO: optionally use PriorityQueue
		// O(N^2) like this, O(log N) with priority queue. But in my tests, priority queues only start pulling ahead in large graphs
		N minElt;
		bool found = false;
		foreach (elt; open) {
			if (!found || dist[elt] < dist[minElt]) {
				minElt = elt;
				found = true;
			}
		}
		if (found) open = open.filter!(i => i != minElt).array;
		
		N current = minElt;
		// check adjacents, calculate distance, or  - if it already had one - check if new path is shorter
		foreach(sibling; getAdjacent(current)) {
			
			if (!(sibling in visited)) {
				int alt = dist[current] + getWeight(sibling);
				
				// any node that is !visited and has a distance assigned should be in open set.
				if (!open.canFind(sibling)) open ~= sibling; // may be already in there

				int oldDist = sibling in dist ? dist[sibling] : int.max;

				if (alt < oldDist) {
					// set or update distance
					dist[sibling] = alt;
					// build back-tracking map
					prev[sibling] = current;
				}
			}
		}

		// A visited node will never be checked again.
		visited[current] = true;

		if (dest == current) {
			break;	
		}
	}

	N current = dest;
	while (current != source) {
		writefln("%s %s %s", current, dist[current], getWeight(current));
		current = prev[current];
	}
	return dist[dest];
}


auto solve (string fname) {
	string[] lines = readLines(fname);
	Point size = Point(to!int(lines[0].length), to!int(lines.length));
	Grid!int grid = new Grid!int(size.x, size.y);
	foreach(pos; PointRange(size)) {
		string digit = to!string(lines[pos.y][pos.x]);
		grid.set(pos, to!int(digit));
	}

	int cost = dijkstra!Point(
		Point(0),
		size - 1,
		n => getAdjacent(grid, n),
		n => grid.get(n)
	);

	return [ cost ];
}

void main() {
	assert (solve("test") == [ 40 ]);
	writeln (solve("input")); // 714 is correct
}
