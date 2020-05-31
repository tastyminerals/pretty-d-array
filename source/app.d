import pretty_array;
import std.stdio;
import std.array;
import mir.ndslice;

import std.algorithm : each, count;
import std.range : chunks;
import std.traits : isArray;
import std.conv;

void main()
{
	auto marr = [2, 3, 7, 8].iota!int(1).fuse;
	auto darr = [
		10.4, 200.14, -40.203, 0.00523, 5, 2.56, 39.901, 56.12, 2.5, 1.2,
		-0.22103, 89091, 3, 5, 1, 0
	];
	auto darr2 = darr.chunks(4).array.chunks(2).array;
	writeln(darr2.getShape);
	marr.prettyArr.writeln;
	// darr2.prettyArr.writeln;

	// 	writeln("│┌                   ┐│
	// ││ 1  2  3 ░  4  5  6││
	// ││ 7  8  9 ░ 10 11 12││
	// ││░░░░░░░░░░░░░░░░░░░││
	// ││13 14 15 ░ 16 17 18││
	// ││19 20 21 ░ 22 23 24││
	// │└                   ┘│
	// 	");

	// 	writeln("
	// │┌                   ┐│
	// ││ 1  2  3 ·  4  5  6││
	// ││ 7  8  9 · 10 11 12││
	// ││···················││
	// ││13 14 15 · 16 17 18││
	// ││19 20 21 · 22 23 24││
	// │└                   ┘│
	// 	");

}
