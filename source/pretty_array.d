/**
    module docstring goes here
*/
module pretty_array;

import std.array : join, array;
import std.conv : to;
import std.utf : byCodeUnit;
import std.typecons : tuple, Tuple;
import mir.ndslice;

import std.stdio;

private enum Frame : string
{
    ltAngle = "┌",
    lbAngle = "└",
    rtAngle = "┐",
    rbAngle = "┘",
    vBar = "│",
    newline = "\n",
    dash = "─",
    dot = "·",
    space = " "
}

size_t[] getShape(T : int)(T obj, size_t[] dims = null)
{
    return dims;
}

size_t[] getShape(T : double)(T obj, size_t[] dims = null)
{
    return dims;
}

/++
Get the shape of a D array.
The array must have correct dimensions otherwise the column index will not be consistent.
+/
size_t[] getShape(T)(T obj, size_t[] dims = null)
in
{
    import std.traits : isArray;

    assert(isArray!(typeof(obj)));
}
do
{
    dims ~= obj.length.to!int;
    return getShape!(typeof(obj[0]))(obj[0], dims);
}

/++
Get the longest string length of a row, construct a row with the longest string elements.
We need to know the longest string length of the row to calculate the correct padding between the frames.
We need to keep the row with longest string elements to correctly right-align all array elements.
+/
private Tuple!(size_t, "strlen", string[], "row") getMaxStrLenAndMaxRow(T)(T arrSlice)
{
    auto slice2D = arrSlice.flattened.chunks(arrSlice.shape[$ - 1]);
    size_t maxStrRowLen;
    string[] row, maxRow;

    // fill the empty array with the number of row elements
    for (int i; i < slice2D[0].length; i++)
    {
        maxRow ~= "0";
    }

    // construct the row with longest string elements
    for (int i; i < slice2D.shape[0]; i++)
    {
        row = slice2D[i].map!(a => a.to!string).array;
        for (int j; j < slice2D[i].length; j++)
        {
            maxRow[j] = maxRow[j].length < row[j].length ? row[j] : maxRow[j];
        }
    }
    maxStrRowLen = maxRow.join.length + slice2D[0].length - 1;
    return Tuple!(size_t, "strlen", string[], "row")(maxStrRowLen, maxRow);
}

/++
Construct the padding between frame angles.
Use white space if padding string is not provided.
+/
private string getPadding(T)(T arrShape, size_t maxStrRowLen, string padStr = Frame.space)
{
    return padStr.byCodeUnit.repeat((arrShape.length < 2
            ? 0 : arrShape.length - 2) * 2 + maxStrRowLen).join;
}

private size_t lenDiff()(string a, string b)
{
    return a.length > b.length ? a.length - b.length : 0;
}

private string prettyFrame(T)(T arrSlice) if (arrSlice.shape.length == 1)
{
    return Frame.vBar ~ arrSlice.map!(a => a.to!string).join(" ") ~ Frame.vBar ~ Frame.newline;
}

private string prettyFrame(T)(T arrSlice, string addedFrame, Tuple!(size_t,
        "strlen", string[], "row") maxRow) if (arrSlice.shape.length == 2)
{
    string arrStr;
    for (int i; i < arrSlice.shape[0]; i++)
    {
        string[] newRow;
        for (int j; j < arrSlice[i].length; j++)
        {
            // insert white spaces before the element to right align it
            newRow ~= " ".repeat(lenDiff(maxRow.row[j],
                    arrSlice[i][j].to!string)).join ~ arrSlice[i][j].to!string;
        }
        arrStr ~= addedFrame ~ newRow.join(" ") ~ addedFrame ~ Frame.newline;
    }
    return arrStr;
}

private string prettyFrame(T)(T arrSlice, string addedFrame, Tuple!(size_t,
        "strlen", string[], "row") maxRow) if (arrSlice.shape.length > 2)
{
    string arrStr;
    for (int i; i < arrSlice.shape[0]; i++)
    {
        string padding = getPadding!(typeof(arrSlice[i].shape))(arrSlice[i].shape, maxRow.strlen);
        arrStr ~= addedFrame ~ Frame.ltAngle ~ padding ~ Frame.rtAngle ~ addedFrame ~ Frame.newline;
        arrStr ~= prettyFrame!(typeof(arrSlice[i]))(arrSlice[i], addedFrame ~ Frame.vBar, maxRow);
        arrStr ~= addedFrame ~ Frame.lbAngle ~ padding ~ Frame.rbAngle ~ addedFrame ~ Frame.newline;
    }
    return arrStr;
}

// N-D array
string prettyArr(T)(T arr)
in
{
    assert(isConvertibleToSlice!(typeof(arr)));
}
do
{
    string arrStr;
    auto arrSlice = arr.fuse; // convert to Mir Slice by GC allocating with fuse
    bool truncate = arrSlice.flattened.length > 300 ? true : false; // check if we need array truncation
    auto maxRow = arrSlice.getMaxStrLenAndMaxRow;
    string padding = getPadding!(typeof(arrSlice.shape))(arrSlice.shape, maxRow.strlen);

    arrStr ~= Frame.ltAngle ~ padding ~ Frame.rtAngle ~ Frame.newline;
    static if (arrSlice.shape.length > 1)
    {
        arrStr ~= prettyFrame!(typeof(arrSlice))(arrSlice, Frame.vBar, maxRow);
    }
    else
    {
        arrStr ~= prettyFrame!(typeof(arrSlice))(arrSlice);
    }

    arrStr ~= Frame.lbAngle ~ padding ~ Frame.rbAngle ~ Frame.newline;
    return arrStr;
}

unittest
{
    import std.range : chunks;

    int[] a0 = [200, 1, -3, 0, 0, 8501, 23];
    string testa0 = "┌                    ┐
│200 1 -3 0 0 8501 23│
└                    ┘
";
    assert(prettyArr!(typeof(a0))(a0) == testa0);

    auto a = [5, 2].iota!int(1).fuse;
    auto maxa = a.getMaxStrLenAndMaxRow;
    assert(getPadding!(typeof(a.shape))(a.shape, maxa.strlen).length == 4);
    string testa = "┌    ┐
│1  2│
│3  4│
│5  6│
│7  8│
│9 10│
└    ┘
";
    assert(prettyArr!(typeof(a))(a) == testa);

    auto b = [2, 2, 6].iota!int(1).fuse;
    auto maxb = b.getMaxStrLenAndMaxRow;
    assert(getPadding!(typeof(b.shape))(b.shape, maxb.strlen).length == 19);
    string testb = "┌                   ┐
│┌                 ┐│
││ 1  2  3  4  5  6││
││ 7  8  9 10 11 12││
│└                 ┘│
│┌                 ┐│
││13 14 15 16 17 18││
││19 20 21 22 23 24││
│└                 ┘│
└                   ┘
";
    assert(prettyArr!(typeof(b))(b) == testb);
    int[] carr = [
        1000, 21, 1232, 4, 5, 36, 1207, 18, 9, 10, -1, 12, 133, -14, 21915, 16
    ];
    auto c = carr.chunks(2).array.chunks(4).array.chunks(2).array; // jagged D array
    string testc = "┌             ┐
│┌           ┐│
││┌         ┐││
│││ 1000  21│││
│││ 1232   4│││
│││    5  36│││
│││ 1207  18│││
││└         ┘││
││┌         ┐││
│││    9  10│││
│││   -1  12│││
│││  133 -14│││
│││21915  16│││
││└         ┘││
│└           ┘│
└             ┘
";
    assert(prettyArr!(typeof(c))(c) == testc);

    auto d = [3, 1, 2, 1].iota!int(1).fuse;
    string testd = "┌     ┐
│┌   ┐│
││┌ ┐││
│││1│││
│││2│││
││└ ┘││
│└   ┘│
│┌   ┐│
││┌ ┐││
│││3│││
│││4│││
││└ ┘││
│└   ┘│
│┌   ┐│
││┌ ┐││
│││5│││
│││6│││
││└ ┘││
│└   ┘│
└     ┘
";
    assert(prettyArr!(typeof(d))(d) == testd);
}

/*

░
▒
▓
···
…


│┌                   ┐│
││ 1  2  3 ░  4  5  6││
││ 7  8  9 ░ 10 11 12││
││░ ░ ░ ░ ░ ░ ░ ░ ░ ░││
││13 14 15 ░ 16 17 18││
││19 20 21 ░ 22 23 24││
│└                   ┘│
│┌                   ┐│
││ 1  2  3 ░  4  5  6││
││ 7  8  9 ░ 10 11 12││
││░░░░░░░░░░░░░░░░░░░││
││13 14 15 ░ 16 17 18││
││19 20 21 ░ 22 23 24││
│└                   ┘│

│┌                   ┐│
││ 1  2  3 ·  4  5  6││
││ 7  8  9 · 10 11 12││
││···················││
││13 14 15 · 16 17 18││
││19 20 21 · 22 23 24││
│└                   ┘│



In [26]: a = np.random.randint(0, 10, [300, 300])
In [27]: a
Out[27]:
array([[6, 0, 1, ..., 9, 6, 9],
       [4, 9, 0, ..., 6, 3, 6],
       [7, 5, 9, ..., 1, 0, 0],
       ...,
       [5, 4, 6, ..., 6, 1, 3],
       [9, 6, 9, ..., 1, 4, 1],
       [9, 4, 4, ..., 3, 4, 0]])

In [11]: a = np.random.randint(0, 100, [800, 2])

In [12]: a
Out[12]:
array([[70, 94],
       [47, 68],
       [96, 55],
       ...,
       [71, 22],
       [40, 95],
       [85, 65]])


In [13]: a = np.random.randint(0, 100, [2, 800, 2])

In [14]: a
Out[14]:
array([[[73, 93],
        [38, 47],
        [12, 27],
        ...,
        [55, 39],
        [70, 24],
        [39, 76]],

       [[76, 48],
        [71, 19],
        [ 6, 62],
        ...,
        [55, 16],
        [32, 93],
        [69, 35]]])


*/
