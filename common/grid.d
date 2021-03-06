module common.grid;

import common.vec;
import common.coordrange;

import std.conv;

class Grid(T) {
	T[] data;
	Point size;
	
	@property int width() const { return size.x; }
	@property int height() const { return size.y; }

	this(ulong width, ulong height, T initialValue = T.init) {
		this(Point(cast(int)width, cast(int)height), initialValue);
	}

	this(Point size, T initialValue = T.init) {
		this.size = size;
		data = [];
		data.length = size.x * size.y;
		if (initialValue != T.init) {
			foreach(ref cell; data) {
				cell = initialValue;
			}
		}
	}

	bool inRange(Point p) const {
		return (p.x >= 0 && p.x < size.x && p.y >= 0 && p.y < size.y);
	}

	ulong toIndex(Point p) const {
		return p.x + (size.x * p.y);
	}

	void set(Point p, T val) {
		assert(inRange(p));
		data[toIndex(p)] = val;
	}

	T get(Point p) const {
		assert(inRange(p));
		return data[toIndex(p)];
	}

	ref T get(Point p) {
		assert(inRange(p));
		return data[toIndex(p)];
	}

	string format(string cellSep = ", ", string lineSep = "\n") {
		char[] result;
		int i = 0;
		
		const int lineSize = size.x;
		bool firstLine = true;
		bool firstCell = true;
		foreach (base; PointRange(size)) {
			if (i % lineSize == 0 && !firstLine) {
				result ~= lineSep;
				firstCell = true;
			}
			if (!firstCell) result ~= cellSep;
			result ~= to!string(get(base));
			i++;
			
			firstLine = false;
			firstCell = false;
		}
		return result.idup;
	}

	struct NodeRange {

		Grid!T parent;
		int pos = 0;
		int stride = 1;
		int remain;

		this(Grid!T parent, int stride = 1) {
			this.parent = parent;
			this.stride = stride;
			remain = to!int(parent.data.length);
		}

		/* use ref to support in place-modification */
		ref T front() {
			return parent.data[pos];
		}

		void popFront() {
			pos++;
			remain--;
		}

		bool empty() const {
			return remain <= 0;
		}
		
	}

	NodeRange range() {
		return NodeRange(this);
	}

	override string toString() {
		return format();
	}

}
