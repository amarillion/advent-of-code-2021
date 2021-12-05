module common.coordrange;

import common.vec;

struct CoordRange(T) {
	
	T pos, start, end;

	/* End is exclusive */
	this(T start, T endExclusive) {
		pos = start;
		this.start = start;
		this.end = endExclusive;
	}

	this(T endExclusive) {
		this(T(0), endExclusive);
	}

	T front() {
		return pos;
	}

	void popFront() {
		pos.val[0]++;
		foreach (i; 0 .. pos.val.length - 1) {
			if (pos.val[i] > end.val[i] - 1) {
				pos.val[i] = start.val[i];
				pos.val[i+1]++;
			}
			else {
				break;
			}
		}
	}

	bool empty() const {
		return pos.val[$-1] >= end.val[$-1]; 
	}

}

alias PointRange = CoordRange!Point;

struct Walk(T) {
	T pos;
	T delta;
	int remain;

	this(T start, T delta, int steps) {
		pos = start;
		this.delta = delta;
		remain = steps;
	}

	T front() {
		return pos;
	}

	void popFront() {
		remain--;
		pos = pos + delta;
	}

	bool empty() const {
		return remain <= 0;
	}
}

/** 
 * Walk from A to B in integral increments,
 * preferring diagonal steps if possible.
 *
 *
 * For example:
 * 
 *   A
 *    \
 *     \
 *      \---B
 */
struct DiagonalWalker {
	Point pos;
	Point end;
	bool done;

	this(Point start, Point end) {
		pos = start;
		this.end = end;
		done = false;
	}

	Point front() {
		return pos;
	}

	void popFront() {
		if (pos == end) { done = true; }
		pos = pos + (end - pos).sgn;
	}

	bool empty() const {
		return done;
	}
}

unittest {
	assert(
			DiagonalWalker(Point(0, 0), Point(1, 1)).array 
			== [Point(0, 0), Point(1, 1)]
	);
	assert(DiagonalWalker(Point(0, 0), Point(-2, 0)).array 
			== [Point(0, 0), Point(-1, 0), Point(-2, 0)]
	);
}