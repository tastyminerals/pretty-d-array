# pretty_d_array
Pretty printing multidimensional D arrays.
This small package uses awesome [mir-algorithm](https://github.com/libmir/mir-algorithm) library as a dependency.

Simply put, it is a small dub package that turns your D arrays from this:

```
[[[1, 2, 3, 4, 5, 6, 7, 8], [9, 10, 11, 12, 13, 14, 15, 16], [17, 18, 19, 20, 21, 22, 23, 24], [25, 26, 27, 28, 29, 30, 31, 32], [33, 34, 35, 36, 37, 38, 39, 40], [41, 42, 43, 44, 45, 46, 47, 48], [49, 50, 51, 52, 53, 54, 55, 56]],
[[57, 58, 59, 60, 61, 62, 63, 64], [65, 66, 67, 68, 69, 70, 71, 72], [73, 74, 75, 76, 77, 78, 79, 80], [81, 82, 83, 84, 85, 86, 87, 88], [89, 90, 91, 92, 93, 94, 95, 96], [97, 98, 99, 100, 101, 102, 103, 104], [105, 106, 107, 108, 109, 110, 111, 112]]]
```

into this

```
┌                                 ┐
│┌                               ┐│
││  1   2   3   4   5   6   7   8││
││  9  10  11  12  13  14  15  16││
││ 17  18  19  20  21  22  23  24││
││ 25  26  27  28  29  30  31  32││
││ 33  34  35  36  37  38  39  40││
││ 41  42  43  44  45  46  47  48││
││ 49  50  51  52  53  54  55  56││
│└                               ┘│
│┌                               ┐│
││ 57  58  59  60  61  62  63  64││
││ 65  66  67  68  69  70  71  72││
││ 73  74  75  76  77  78  79  80││
││ 81  82  83  84  85  86  87  88││
││ 89  90  91  92  93  94  95  96││
││ 97  98  99 100 101 102 103 104││
││105 106 107 108 109 110 111 112││
│└                               ┘│
└                                 ┘
```

I think it's much easier to reason about array structure using such simplified form.
Let's see a code example.

```d
import pretty_array;
import std.stdio;
import std.array;
import std.range : chunks;

void main() {
    auto arr = [10.4, 200.14, -40.203, 0.00523, 5, 2.56, 39.901, 56.12, 2.5, 1.2, -0.22103, 89091, 3, 5, 1, 0];
    auto arr3D = darr.chunks(4).array.chunks(2).array; // convert it to [2 x 2 x 4] array
    arr3D.prettyArr.writeln;
}
```

Use `prettyArr` function to restructure your array.

```
┌                              ┐
│┌                            ┐│
││10.4 200.14  -40.203 0.00523││
││   5   2.56   39.901   56.12││
│└                            ┘│
│┌                            ┐│
││ 2.5    1.2 -0.22103   89091││
││   3      5        1       0││
│└                            ┘│
└                              ┘
```

Sometimes, you don't need to see complete array but just visualize its structure.
`prettyArr` truncates big enough arrays to save screen space.

```d
auto bigArr = [300, 600].iota.int!(1).fuze;
bigArr.prettyArr.writeln;
```

will truncate the array into the following

```
┌                                           ┐
│     1      2      3 ░    598    599    600│
│   601    602    603 ░   1198   1199   1200│
│  1201   1202   1203 ░   1798   1799   1800│
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│178201 178202 178203 ░ 178798 178799 178800│
│178801 178802 178803 ░ 179398 179399 179400│
│179401 179402 179403 ░ 179998 179999 180000│
└                                           ┘
```

You can configure the truncation parameters and the actual frame symbols in the source code.

### TODO
* Representation of "nan" and "inf" elements.
* Floating point truncation.
* Small floating point numbers suppression.
* Expose configuration to the outside.