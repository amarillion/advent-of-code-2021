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
import std.uni;
import common.util;
import common.sparsegrid;

class Node {
	Node left;
	Node right;
	int literal;
	bool isLiteral;

	override string toString() const {
		if (isLiteral) {
			return to!string(literal);
		}
		else {
			return "(" ~ left.toString() ~ "," ~ right.toString() ~ ")";
		}
	}
}

bool eq(const Node lhs, const Node rhs) {
	if (lhs is rhs) return true;
	if (lhs is null || rhs is null) return false;
	bool result;
	if (lhs.isLiteral) {
		result = rhs.isLiteral && rhs.literal == lhs.literal;
	}
	else {
		result = eq(lhs.left, rhs.left) && eq(lhs.right, rhs.right);
	}
	return result;
}

Node parse(string t) {
	dchar[] buffer = to!(dchar[])(t);
	return parseRec(buffer);
}

Node parseRec(ref dchar[] t) {
	Node result = new Node();
	dchar current = t.front;
	t.popFront;
	if (current == '[') {
		result.isLiteral = false;
		result.left = parseRec(t);
		assert(t.front == ',' , "Expected ',': " ~ to!string(t.front));
		t.popFront;
		result.right = parseRec(t);
		assert(t.front == ']', "Expected ']': " ~ to!string(t.front));
		t.popFront;
	}
	else {
		assert(current >= '0' && current <= '9', "Expected digit: " ~ to!string(current));
		result.isLiteral = true;
		result.literal = current - '0';
		if (t.front >= '0' && t.front <= '9') {
			result.literal *= 10;
			result.literal += t.front - '0';
			t.popFront;
		}
	}
	return result;
}

Node add(Node left, Node right) {
	Node result = new Node();
	result.isLiteral = false;
	result.left = left;
	result.right = right;
	return result;
}

Node explodeFind(Node current, int level) {
	if (current.isLiteral) return null;
	if (current.left.isLiteral && current.right.isLiteral && level >= 4) {
		return current;
	}
	else {
		auto found = explodeFind(current.left, level + 1);
		if (found !is null) return found;

		found = explodeFind(current.right, level + 1);
		return found;
	}
}

Node split(Node root) {
	isSplit(root);
	return root;
}

bool isSplit(Node root) {
	foreach(current; leftToRight(root)) {
		if (current.literal >= 10) {
			current.isLiteral = false;
			current.left = new Node();
			current.left.isLiteral = true;
			current.left.literal = current.literal / 2;
			current.right = new Node();
			current.right.isLiteral = true;
			current.right.literal = current.literal / 2 + current.literal % 2;
			current.literal = 0; // redundant cleanup
			return true;
		}
	}
	return false;
}

auto leftToRight(Node root) {
	Node[] result = [];
	Node[] stack = [ root ];
	while (stack.length > 0) {
		Node current = stack.front;
		stack.popFront;
		if (!current.isLiteral) {
			stack = [ current.left, current.right ] ~ stack;
		}
		else {
			result ~= current;
		}
	}
	return result;
}

Node explode(Node input) {
	isExplode(input);
	return input;
}

bool isExplode(Node input) {
	Node found = explodeFind(input, 0);
	if (found is null) return false;
	// Node found = scan(input, chain);
	
	const left = found.left.literal;
	const right = found.right.literal;

	found.isLiteral = true;
	found.literal = 0;
	
	Node[] leaves = leftToRight(input);

	
	Node[] toRight = find(leaves, found);
	Node[] toLeft = find(retro(leaves), found).array;
	if (toLeft.length > 1) toLeft[1].literal += left;
	if (toRight.length > 1) toRight[1].literal += right;
	return true;
}

Node reduce(Node root) {
	bool changes = true;
	while(changes) {
		// writeln("Reduce: ", root);
		changes = isExplode(root);
		if (changes) continue;
		changes = isSplit(root);
	}
	return root;
}

int magnitude(Node node) {
	if (node.isLiteral) {
		return node.literal;
	}
	else {
		return 3 * magnitude(node.left) + 2 * magnitude(node.right);
	}
}

auto solve (string fname) {
	string[] lines = readLines(fname);
	
	Node acc = parse(lines[0]);
	foreach(line; lines[1..$]) {
		acc = add (acc, parse(line));
		reduce(acc);
	}
	int part1 = magnitude(acc);

	int maxSum = 0;
	for(int i = 0; i < lines.length; ++i) {
		for(int j = 0; j < lines.length; ++j) {
			if (i == j) continue;
			Node ni = parse(lines[i]);
			Node nj = parse(lines[j]);
			
			Node x = add(ni, nj);
			reduce(x);
			int val = magnitude(x);
			if (val > maxSum) {
				maxSum = val;
			}
		}
	}
	return [ part1, maxSum ];
}

void main() {
	assert(eq(parse("[1,[2,3]]"), parse("[1,[2,3]]")));
	assert(!eq(parse("[1,[2,3]]"), parse("[1,2]")));

	assert(eq(add(parse("[1,2]"), parse("[[3,4],5]")), parse("[[1,2],[[3,4],5]]")));

	assert(eq(explode(parse("[1,2]")), parse("[1,2]")));
	assert(eq(explode(parse("[[[[[9,8],1],2],3],4]")), parse("[[[[0,9],2],3],4]")));
	assert(eq(explode(parse("[7,[6,[5,[4,[3,2]]]]]")), parse("[7,[6,[5,[7,0]]]]")));
	assert(eq(explode(parse("[[6,[5,[4,[3,2]]]],1]")), parse("[[6,[5,[7,0]]],3]")));
	assert(eq(explode(parse("[[3,[2,[1,[7,3]]]],[6,[5,[4,[3,2]]]]]")), parse("[[3,[2,[8,0]]],[9,[5,[4,[3,2]]]]]")));

	assert(eq(split(parse("10")), parse("[5,5]")));
	assert(eq(split(parse("11")), parse("[5,6]")));
	
	assert(eq(
		reduce(parse("[[[[[4,3],4],4],[7,[[8,4],9]]],[1,1]]")), 
		parse("[[[[0,7],4],[[7,8],[6,0]]],[8,1]]")
	));
	assert(magnitude(parse("[[1,2],[[3,4],5]]")) == 143);
	assert(magnitude(parse("[[[[0,7],4],[[7,8],[6,0]]],[8,1]]")) == 1384);

	assert (solve("test") == [ 4140, 3993 ]);
	writeln (solve("input"));
}
