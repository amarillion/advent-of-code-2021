#!/usr/bin/env -S rdmd -g -I..

import common.io;
import std.stdio;
import std.conv;
import std.algorithm;
import std.array;
import std.math;
import std.range;
import std.typecons;
import std.format;

enum NodeType { LITERAL, BINARY, INPUT, TERNARY }
enum BinaryOp { ADD, MUL, DIV, MOD }

enum string[BinaryOp] opFormatStr = [
	BinaryOp.ADD: "(%s + %s)",
	BinaryOp.MUL: "(%s * %s)",
	BinaryOp.DIV: "(%s / %s)",
	BinaryOp.MOD: "(%s %% %s)",
];

class Node {
	NodeType type;
	long value;
	
	BinaryOp op;
	Node left;
	Node right;

	long trueVal;
	long falseVal;

	long[] possibleVals;

	long lowerBound;
	long upperBound;
	
	private this() {}

	// print recursively
	override string toString() const {
		final switch(type) {
			case NodeType.LITERAL: return to!string(value);
			case NodeType.INPUT: return format("i[%s]", value);
			case NodeType.BINARY: return format(opFormatStr[op], left, right);
			case NodeType.TERNARY: return format("(%s == %s ? %s : %s)", left, right, trueVal, falseVal);
		}
	}

	static Node literal(long val) {
		Node n = new Node();
		n.type = NodeType.LITERAL;
		n.value = val;
		n.lowerBound = val;
		n.upperBound = val;
		n.possibleVals = [ val ];
		return n;
	}

	bool isLiteral() { return type == NodeType.LITERAL; }
	bool isTernary() { return type == NodeType.TERNARY; }
	bool isInput() { return type == NodeType.INPUT; }
	bool isMul() { return type == NodeType.BINARY && op == BinaryOp.MUL; }

	bool isLiteral(long v) {
		return type == NodeType.LITERAL && value == v;
	}

	long eval(int[14] i) {
		final switch(type) {
			case NodeType.LITERAL: return value;
			case NodeType.BINARY: {
				final switch (op) {
					case BinaryOp.ADD: return left.eval(i) + right.eval(i);
					case BinaryOp.DIV: return left.eval(i) / right.eval(i);
					case BinaryOp.MOD: return left.eval(i) * right.eval(i);
					case BinaryOp.MUL: return left.eval(i) * right.eval(i);
				}
			}
			case NodeType.INPUT: return i[value];
			case NodeType.TERNARY: return left.eval(i) == right.eval(i) ? trueVal: falseVal;
		}
	}

	override bool opEquals(const Object o) const {
		Node rhs = (cast(Node) o);
		if (type != rhs.type) return false;
		final switch(type) {
			case NodeType.LITERAL: return value == rhs.value;
			case NodeType.TERNARY: return (left == rhs.left 
				&& right == rhs.right && trueVal == rhs.trueVal && falseVal == rhs.falseVal);
			case NodeType.BINARY: return op == rhs.op && left == rhs.left && right == rhs.right;
			case NodeType.INPUT: return value == rhs.value;
		}
	}

	static Node ternary(Node left, Node right, long trueVal = 1, long falseVal = 0) {
		if (left.isLiteral() && right.isLiteral()) return Node.literal(left.value == right.value ? 1 : 0);
		
		// more experimental optimizations
		// ((a == b ? x : y) == y ? 1 : 0) becomes (a == b ? 0 : 1)
		if (left.isTernary() && right.isLiteral(falseVal)) {
			return ternary(left.left, left.right, 0, 1);
		}
		// ((a == b ? x : y) == x ? 1 : 0) becomes (a == b ? 1 : 0)
		if (left.isTernary() && right.isLiteral(trueVal)) {
			return ternary(left.left, left.right, 1, 0);
		}
		
		// if input ranges don't overlap, result is always false.
		if (left.upperBound < right.lowerBound || left.lowerBound > right.upperBound) {
			return Node.literal(0);
		}

		Node n = new Node();
		n.type = NodeType.TERNARY;
		n.left = left;
		n.right = right;
		n.trueVal = trueVal;
		n.falseVal = falseVal;
		n.lowerBound = min(trueVal, falseVal);
		n.upperBound = max(trueVal, falseVal);
		
		n.possibleVals = cartesianProduct(left.possibleVals, right.possibleVals)
			.map!(a => a[0] == a[1] ? trueVal : falseVal).array;
		sort(n.possibleVals);
		return n;
	}

	static Node binary(BinaryOp _op, Node left, Node right) {
		// let's simplify
		switch(_op) {
			case BinaryOp.MUL:
				if (left.isLiteral(0) || right.isLiteral(0)) return Node.literal(0);
				if (right.isLiteral(1)) return left;
				if (left.isLiteral(1)) return right;
				if (left.isLiteral() && right.isLiteral()) return Node.literal(left.value * right.value);
				break;
			case BinaryOp.ADD:
				if (right.isLiteral(0)) return left;
				if (left.isLiteral(0)) return right;
				if (left.isLiteral() && right.isLiteral()) return Node.literal(left.value + right.value);

				// (a * c) + (b * c) = (a + b) * c
				if (left.isMul() && right.isMul() && left.right == right.right) {
					return Node.binary(BinaryOp.MUL, Node.binary(BinaryOp.ADD, left.left, right.left), left.right); 
				}
				break;
			case BinaryOp.DIV:
				if (right.isLiteral(1)) return left;
				if (left.isLiteral(1)) return right;
				if (left.isLiteral(0)) return Node.literal(0);
				break;
			case BinaryOp.MOD:
				if (left.isLiteral(0)) return Node.literal(0);
				
				// modulo has no effect if left can not possibly be larger than right
				if (left.upperBound < right.lowerBound) {
					return left;
				}

				// apply to trueval / falseVal instead
				if (left.isTernary() && right.isLiteral()) {
					return Node.ternary(left.left, left.right, left.trueVal % right.value, left.falseVal % right.value);
				}
				break;
			default: // no further optimizations implemented
		}

		Node n = new Node();
		n.type = NodeType.BINARY;
		n.op = _op;
		n.left = left;
		n.right = right;

		// calculate bounds...
		final switch(_op) {
			case BinaryOp.ADD:
				n.lowerBound = left.lowerBound + right.lowerBound;
				n.upperBound = left.upperBound + right.upperBound;
				n.possibleVals = cartesianProduct(left.possibleVals, right.possibleVals).map!(a => a[0] + a[1]).array;
				break;
			case BinaryOp.DIV:
				n.lowerBound = left.lowerBound / right.lowerBound;
				n.upperBound = left.upperBound / right.upperBound;
				n.possibleVals = cartesianProduct(left.possibleVals, right.possibleVals).map!(a => a[0] / a[1]).array;
				break;
			case BinaryOp.MUL:
				n.lowerBound = left.lowerBound * right.lowerBound;
				n.upperBound = left.upperBound * right.upperBound;
				n.possibleVals = cartesianProduct(left.possibleVals, right.possibleVals).map!(a => a[0] * a[1]).array;
				break;
			case BinaryOp.MOD:
				n.lowerBound = 0;
				n.upperBound = min(left.upperBound, right.upperBound);
				n.possibleVals = cartesianProduct(left.possibleVals, right.possibleVals).map!(a => a[0] % a[1]).array;
				break;
		}

		sort(n.possibleVals);
		n.possibleVals = uniq(n.possibleVals).array;
		return n;
	}

	static Node input(long inputNo, int[14] pinned) {
		Node n = new Node();
		n.type = NodeType.INPUT;
		n.value = inputNo;
		if (pinned[inputNo] == 0) {
			n.lowerBound = 1;
			n.upperBound = 9;
			n.possibleVals = [1, 2, 3, 4, 5, 6, 7, 8, 9];
		}
		else {
			n.lowerBound = pinned[inputNo];
			n.upperBound = pinned[inputNo];
			n.possibleVals = [ pinned[inputNo] ];
		}
		return n;
	}
}

bool isVarName(string val) {
	return ["x", "y", "z", "w"].canFind(val);
}

class Parser {

	Node[string] variables;
	int currentInputCounter;

	void parse(string[] lines, int[14] pinned) {
		variables = [
			"w": Node.literal(0),
			"x": Node.literal(0),
			"y": Node.literal(0),
			"z": Node.literal(0),
		];
		currentInputCounter = 0;

		Node fromRval(string rval) {
			assert(rval != "");
			if (isVarName(rval)) {
				return variables[rval];
			}
			return Node.literal(to!long(rval));
		}

		foreach(i, line; lines) {
			// parse line
			string[] parts = line.split(" ");
			string op = parts[0];
			string lval = parts[1];
			string rval = parts.length > 2 ? parts[2] : "";
			assert(isVarName(lval));
			switch(op) {
				case "inp":
					variables[lval] = Node.input(currentInputCounter++, pinned);
					break;
				case "add": 
					variables[lval] = Node.binary(BinaryOp.ADD, variables[lval], fromRval(rval));
					break;
				case "mul": 
					variables[lval] = Node.binary(BinaryOp.MUL, variables[lval], fromRval(rval));
					break;
				case "div": 
					variables[lval] = Node.binary(BinaryOp.DIV, variables[lval], fromRval(rval));
					break;
				case "mod": 
					variables[lval] = Node.binary(BinaryOp.MOD, variables[lval], fromRval(rval));
					break;
				case "eql": 
					variables[lval] = Node.ternary(variables[lval], fromRval(rval));
					break;
				default: assert(0);
			}

			// // WRITE EACH INSTRUCTION		
			// writefln("---\nINSTRUCTION %3d:  %s\n", i + 1, line);
			// foreach(k, v; variables) {
			// 	writefln("  %s = %s;       %s..%s %s", k, v, v.lowerBound, v.upperBound, v.possibleVals);
			// }

		}
	}
}

auto solve (string fname) {
	string[] lines = readLines(fname);

	int[14] pinned =[1,0,0,0,0,0,0,0,0,0,0,0,0,0];
	int pos = 0;

	while(true) {
		auto p = new Parser();
		p.parse(lines, pinned);
		string k = "z";
		Node z = p.variables[k];
		sort(z.possibleVals);
		writefln("%s -> %s", pinned, z.possibleVals[0]);
		if (z.possibleVals[0] == 0) {
			// potential match!
			pos++;
			if (pos >= pinned.length) break;
			pinned[pos] = 1;
		}
		else {
			// not a match
			pinned[pos]++;
			while (pinned[pos] == 10) {
				pinned[pos] = 0;
				// backtrack!
				pos--;
				pinned[pos]++;
			}
		}
	}

}

void printDeduplicated(string var, Node root) {
	int[Node] eqs;
	int[Node] seen;
	int eqCounter = 1;

	void countSubtrees(Node node) {
		if (node.isInput() || node.isLiteral()) {
			return;
		}
		seen[node]++;
		if (seen[node] == 1) {
			countSubtrees(node.left);
			countSubtrees(node.right);
		}
		else if (seen[node] == 2) {
			eqs[node] = eqCounter++;
		}
	}
	countSubtrees(root);

	string eqToString(Node node, bool root = false) {
		if (!root && node in eqs) {
			return format("%s_%s", var, eqs[node]);
		}

		final switch(node.type) {
			case NodeType.LITERAL: return to!string(node.value);
			case NodeType.INPUT: return format("i[%s]", node.value);
			case NodeType.BINARY: return format(opFormatStr[node.op], eqToString(node.left), eqToString(node.right));
			case NodeType.TERNARY: return format("(%s == %s ? %s : %s)", eqToString(node.left), eqToString(node.right), node.trueVal, node.falseVal);
		}
	}

	Node[] keys = eqs.keys();
	sort!((a, b) => eqs[a] < eqs[b])(keys);
	foreach(k; keys) {
		int v = eqs[k];
		writefln("long %s_%s = %s; // %s..%s", var, v, eqToString(k, true), k.lowerBound, k.upperBound);
	}
	writefln("long %s = %s; // [%s..%s]", var, eqToString(root), root.lowerBound, root.upperBound);
}

void main() {
	solve("input");
}
