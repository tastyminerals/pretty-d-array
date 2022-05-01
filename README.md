# pretty\_d\_array

[Pretty-printing multidimensional D arrays](https://tastyminerals.github.io/tasty-blog/dlang/2020/06/25/pretty_printing_arrays.html).

This small package uses awesome [mir-algorithm](https://github.com/libmir/mir-algorithm) library as a dependency.

Simply put, it is a small dub package that turns your D arrays from this:

```
[[[1, 2, 3, 4, 5, 6, 7, 8], [9, 10, 11, 12, 13, 14, 15, 16], [17, 18, 19, 20, 21, 22, 23, 24], [25, 26, 27, 28, 29, 30, 31, 32], [33, 34, 35, 36, 37, 38, 39, 40], [41, 42, 43, 44, 45, 46, 47, 48], [49, 50, 51, 52, 53, 54, 55, 56]],
[[57, 58, 59, 60, 61, 62, 63, 64], [65, 66, 67, 68, 69, 70, 71, 72], [73, 74, 75, 76, 77, 78, 79, 80], [81, 82, 83, 84, 85, 86, 87, 88], [89, 90, 91, 92, 93, 94, 95, 96], [97, 98, 99, 100, 101, 102, 103, 104], [105, 106, 107, 108, 109, 110, 111, 112]]]
```

into this

```
┌                               ┐
│  1   2   3   4   5   6   7   8│
│  9  10  11  12  13  14  15  16│
│ 17  18  19  20  21  22  23  24│
│ 25  26  27  28  29  30  31  32│
│ 33  34  35  36  37  38  39  40│
│ 41  42  43  44  45  46  47  48│
│ 49  50  51  52  53  54  55  56│
└                               ┘
┌                               ┐
│ 57  58  59  60  61  62  63  64│
│ 65  66  67  68  69  70  71  72│
│ 73  74  75  76  77  78  79  80│
│ 81  82  83  84  85  86  87  88│
│ 89  90  91  92  93  94  95  96│
│ 97  98  99 100 101 102 103 104│
│105 106 107 108 109 110 111 112│
└                               ┘
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

```
┌                            ┐
│10.4 200.14  -40.203 0.00523│
│   5   2.56   39.901   56.12│
└                            ┘
┌                            ┐
│ 2.5    1.2 -0.22103   89091│
│   3      5        1       0│
└                            ┘
```

Pretty-printing arrays with strings or chars is also possible.

```d
auto charArr = [[['a', 'b', 'c', 'd'], ['e', 'f', 'g', 'h']]];
charArr.prettyArr.writeln;
```
```
┌       ┐
│a b c d│
│e f g h│
└       ┘
```

```d
auto strArr = [[["abt", "bat"], ["dac", "eac"]], [["eab", "jua"], ["uia", "vma"]]];
strArr.prettyArr.writeln;
```
```
┌       ┐
│┌     ┐│
││a b t││
││b a t││
│└     ┘│
│┌     ┐│
││d a c││
││e a c││
│└     ┘│
└       ┘
┌       ┐
│┌     ┐│
││e a b││
││j u a││
│└     ┘│
│┌     ┐│
││u i a││
││v m a││
│└     ┘│
└       ┘
```

Standard array does not have `.shape` method like Mir slices.
Therefore, `pretty_array` additionally provides a naive `getShape` function.

```d
strArr.getShape.writeln;
```
```
[2, 2, 2, 3]
```

`prettyArr` also **truncates** big enough arrays to save screen space. You can configure max number of elements allowed before truncation.

```d
auto bigArr = [300, 600].iota!int(1).fuse;
bigArr.prettyArr.writeln;
```

Will truncate the array into the following.

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

`pretty_array` package contains

* `prettyArr` -- converts an array into a pretty string.
* `PrettyArrConfig` -- array formatting configuration.
* `getShape` -- returns a shape of standard D array.

## Formatting Configuration

You can configure some of the default formatting parameters via `PrettyArrConfig`.

* `edgeItems` -- number of items preceding and following the truncation symbol (defaults to 3).
* `lineWidth` -- max line width allowed without truncation (defaults to 120).
* `precision` -- precision of floating point representations (defaults to 6).
* `suppressExp` -- suppress scientific notation (defaults to true).
* `threshold` -- max array size allowed without truncation (default is 1000 elements).
* `withShape` -- additionally display array shape.

Here are couple of usage examples.

```d
auto a = [[0.000023, 1.234023, 13.443333], [479.311231, -100.001001, -0.412223]];
PrettyArrConfig.precision = 2;
a.prettyArr.writeln;
```

Will reduce the default **floating precision** from 6 to 2.

```
┌                    ┐
│  0.00    1.23 13.44│
│479.31 -100.00 -0.41│
└                    ┘
```

You can also enable **scientific notation** via _e_ suffix.

```d
auto a = [[0.000023, 1.234023, 13.443333], [479.311231, -100.001001, -0.412223]];
PrettyArrConfig.suppressExp = false;
PrettyArrConfig.withShape = true;
a.prettyArr.writeln;
```

```
┌                                        ┐
│2.300000e-05  1.234023e+00  1.344333e+01│
│4.793112e+02 -1.000010e+02 -4.122230e-01│
└                                        ┘
[2 x 3]
```

### Configuring Special Symbols

If for some reason you don't like the awesome truncation symbol `░`, or pretty array frames, you can always edit them in the source code.

Search `pretty_array.d` for

```d
private enum Frame : string
{
    ltAngle = "┌",
    lbAngle = "└",
    rtAngle = "┐",
    rbAngle = "┘",
    vBar = "│",
    newline = "\n",
    whitespace = " ",
    dash = "─",
    empty = "",
    dot = "·",
    truncStr = "░" // TIP: length of this string is 3!
}
```

### Building & Testing

You'll need a D compiler (ldc, dmd, gdc) and dub.

Build a library
```
dub build
```

Test a library
```
dub test
```
