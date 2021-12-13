module common.vec;

import std.conv;

struct vec(int N, V) {
	V[N] val;
	
	@property V x() const { return val[0]; }
	@property void x(V v) { val[0] = v; }
	
	@property V y() const { return val[1]; }
	@property void y(V v) { val[1] = v; }

	static if (N > 2) {
		@property V z() const { return val[2]; }
		@property void z(V v) { val[2] = v; }
	}

	static if (N > 3) {
		@property V w() const { return val[3]; }
		@property void w(V v) { val[3] = v; }
	}

	this(V x, V y, V z = 0, V w = 0) {
		static if (N == 4) {
			val = [x, y, z, w];
		}
		static if (N == 3) {
			val = [x, y, z];
		}
		static if (N == 2) {
			val = [x, y];
		}
	}

	this(V init) {
		foreach (i; 0..N) {
			val[i] = init;
		}
	}

	void lowestCorner(U)(vec!(N, U) p) {
		foreach (i; 0..N) {
			if (p.val[i] < val[i]) { val[i] = p.val[i]; }
		}
	}

	void highestCorner(U)(vec!(N, U) p) {
		foreach (i; 0..N) {
			if (p.val[i] > val[i]) { val[i] = p.val[i]; }
		}
	}

	/** addition */
	vec!(N, V) opBinary(string op)(vec!(N, V) rhs) const if (op == "+") {
		vec!(N, V) result;
		result.val[] = val[] + rhs.val[];
		return result;
	}

	/** substraction */
	vec!(N, V) opBinary(string op)(vec!(N, V) rhs) const if (op == "-") {
		vec!(N, V) result;
		result.val[] = val[] - rhs.val[];
		return result;
	}

	/** add a scalar */
	vec!(N, V) opBinary(string op)(V rhs) const if (op == "+") {
		vec!(N, V) result;
		result.val[] = val[] + rhs;
		return result;
	}

	/** scale up */
	vec!(N, V) opBinary(string op)(V rhs) const if (op == "*") {
		vec!(N, V) result;
		result.val[] = val[] * rhs;
		return result;
	}

	/** substract a scalar */
	vec!(N, V) opBinary(string op)(V rhs) const if (op == "-") {
		vec!(N, V) result;
		result.val[] = val[] - rhs;
		return result;
	}

	/** 
	Applies std.math.sgn to each element in the vector. For example, vec3i(5, 0, -10) becomes vec3i(1, 0, -1)
	*/ 
	vec!(N, V) sgn() const {
		import std.math;
		vec!(N, V) result;
		foreach(i; 0..N) {
			result.val[i] = val[i].sgn;
		}
		return result;
	}

	string toString() const {
		bool first = true;
		char[] result = ['['];
		foreach(i; val) {
			if (!first) {
				result ~= ", ".dup;
			}
			first = false;
			result ~= to!string(i);
		}
		result ~= ']';
		return result.idup;
	}

	int opCmp(ref const vec!(N, V) s) const {
		foreach(i; 0..N) {
			if (s.val[i] > val[i]) return -1;
			if (s.val[i] < val[i]) return 1;
		}
		return 0;
	}
}

unittest {
	Point p1 = Point(2, 0);
	Point p2 = Point(0, 1);
	assert (p1 > p2);
	// assert (Point(2, 0) > Point(1, 0));
	// assert (Point(0, 2) > Point(0, 1));
	// assert (Point(0, 1) > Point(2, 0));
}

alias vec2i = vec!(2, int);
alias Point = vec!(2, int);
alias vec3i = vec!(3, int);
alias vec4i = vec!(4, int);
