/**
This module provides a function for pretty-printing D arrays of various dimensions.
A multidimensional array is represented as a 2D matrix surrounded by nested square frames.
If the array is too big, it will be truncated accordingly.
Array formatting can be configured by changing configuration parameters.

Usage examples:
    import pretty_array;
    import std.stdio;

    int[][] a = [[10, 5, -3], [34, -1, 0]];
    a.prettyArr.writeln;

    import mir.ndslice;
    auto b = [2, 2, 3].iota!int.fuse;
    b.prettyArr.writeln;

    auto c = [
        [0.000023, 1.234023, 13.443333],
        [479.311231, -100.001001, -0.412223]
    ];
    PrettyArrConfig.precision = 2;
    PrettyArrConfig.suppressExp = false;
    c.prettyArr.writeln;
*/
module pretty_array;

import std.array : join, array;
import std.conv : to;
import std.utf : byCodeUnit;
import std.typecons : tuple, Tuple;
import std.traits : isIntegral;
import mir.ndslice;

/++
Array formatting configuration:

    edgeItems -- number of items preceding and following the truncation symbol (defaults to 3)
    lineWidth -- max line width allowed without truncation (defaults to 120)
    precision -- precision of floating point representations (defaults to 6)
    suppressExp -- suppress scientific notation (defaults to true)
    threshold -- max array size allowed without truncation (defaults to 1000 elements)

+/
class PrettyArrConfig
{
    static:
        int edgeItems = 3;
        int lineWidth = 120;
        int precision = 6;
        bool suppressExp = true;
        int threshold = 1000;
}

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
    space = " ",
    truncStr = "░" // TIP: length of this string is 3!
}

ulong[] getShape(T : int)(T obj, ulong[] dims = null)
{
    return dims;
}

ulong[] getShape(T : double)(T obj, ulong[] dims = null)
{
    return dims;
}

/++
Get the shape of a plain D array.
A standalone convenience function for getting array shape without converting to Mir Slices.
The array must have correct dimensions otherwise the column index will not be consistent.
+/
ulong[] getShape(T)(T obj, ulong[] dims = null)
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

// Calculate the length of array elements converted to strings.
private ulong getStrLength(T)(T arrSlice)
{
    if (arrSlice.shape.length == 1)
    {
        return arrSlice.map!(a => a.toString).join.length;
    }
    else
    {
        auto slice2D = arrSlice.flattened.chunks(arrSlice.shape[$ - 1]);
        return slice2D[0].map!(a => a.toString).join.length;
    }
}

private string toString(T)(T obj)
{
    import std.format : format;
    import std.traits : isIntegral;

    if (isIntegral!T)
    {
        return obj.to!string;
    }
    else
    {
        string notation = PrettyArrConfig.suppressExp ? "f" : "e";
        return format("%." ~ (cast(int)(PrettyArrConfig.precision)).to!string ~ notation, obj);
    }
}

// Convert truncated index to real array index.
private ulong convertTruncIdx(ulong idx, ulong truncLen, ulong rowLen)
{
    pragma(inline, true);
    return idx > PrettyArrConfig.edgeItems ? rowLen - (truncLen - idx) : idx;
}

/++
Get the longest string length of a row, construct a row with the longest string elements.
We need to know the longest string length of the row to calculate the correct padding between the frames.
We need to keep the row with longest string elements to correctly right-align all array elements.
+/
private Tuple!(ulong, "strlen", string[], "row") getMaxStrLenAndMaxRow(T)(T arrSlice, bool truncate)
{

    auto slice2D = arrSlice.flattened.chunks(arrSlice.shape[$ - 1]);
    const ulong truncLen = PrettyArrConfig.edgeItems * 2 + 1;
    const bool enoughRows = slice2D.shape[0] > truncLen;
    const bool encoughCols = slice2D[0].length > truncLen;
    ulong maxStrRowLen;
    string[] row, maxRow;

    // fill the empty array with the number of row elements
    // there probably a better way to do it
    for (int i; i < (truncate && encoughCols ? truncLen : slice2D[0].length); i++)
    {
        maxRow ~= "0";
        row ~= "";
    }

    // construct a row with longest string elements
    ulong rowi, colj;
    for (ulong i; i < (truncate && enoughRows ? truncLen : slice2D.shape[0]); i++)
    {
        rowi = truncate && enoughRows ? convertTruncIdx(i, truncLen, slice2D.shape[0]) : i;
        for (ulong j; j < (truncate && encoughCols ? truncLen : slice2D[rowi].length);
                j++)
        {
            colj = truncate && encoughCols ? convertTruncIdx(j, truncLen, slice2D[i].length) : j;
            row[j] = slice2D[rowi][colj].toString;
        }

        for (ulong k; k < row.length; k++)
        {
            if (truncate && encoughCols && (k == PrettyArrConfig.edgeItems))
            {
                maxRow[k] = Frame.truncStr;
                continue;
            }
            maxRow[k] = maxRow[k].length < row[k].length ? row[k] : maxRow[k];
        }
    }
    maxStrRowLen = truncate && encoughCols ? maxRow.join.length + truncLen - Frame.truncStr.length
        : maxRow.join.length + slice2D[0].length - 1;
    return Tuple!(ulong, "strlen", string[], "row")(maxStrRowLen, maxRow);
}

/++
Construct the padding between frame angles.
Use white space if padding string is not provided.
+/
private string getPadding(T)(T arrShape, ulong maxStrRowLen, string padStr = Frame.space)
{
    return padStr.byCodeUnit.repeat((arrShape.length < 2
            ? 0 : arrShape.length - 2) * 2 + maxStrRowLen).join;
}

private ulong lenDiff()(string a, string b)
{
    return a.length > b.length ? a.length - b.length : 0;
}

private string prettyFrame(T)(T arrSlice, bool truncate)
        if (arrSlice.shape.length == 1)
{
    if (truncate)
    {
        string[] leftSlice = arrSlice[0 .. PrettyArrConfig.edgeItems].map!(a => a.toString).array;
        string[] rightSlice = arrSlice[$ - PrettyArrConfig.edgeItems .. $].map!(
                a => a.toString).array;
        return Frame.vBar ~ (leftSlice ~ Frame.truncStr ~ rightSlice)
            .join(" ") ~ Frame.vBar ~ Frame.newline;
    }
    else
    {

        return Frame.vBar ~ arrSlice.map!(a => a.toString).join(" ") ~ Frame.vBar ~ Frame.newline;
    }

}

private string prettyFrame(T)(T arrSlice, string addedFrame, Tuple!(ulong,
        "strlen", string[], "row") maxRow, bool truncate)
        if (arrSlice.shape.length == 2)
{
    string arrStr;
    ulong rowi, colj;
    const ulong truncLen = PrettyArrConfig.edgeItems * 2 + 1;
    const bool enoughRows = arrSlice.shape[0] > truncLen;
    const bool enoughCols = arrSlice.shape[1] > truncLen;

    for (ulong i; i < (truncate && enoughRows ? truncLen : arrSlice.shape[0]); i++)
    {
        string[] newRow;
        rowi = truncate && enoughRows ? convertTruncIdx(i, truncLen, arrSlice.length) : i;
        for (ulong j; j < (truncate && enoughCols ? truncLen : arrSlice[rowi].length);
                j++)
        {
            colj = truncate && enoughCols ? convertTruncIdx(j, truncLen, arrSlice[i].length) : j;
            // insert white spaces before the element to right align it
            newRow ~= " ".repeat(lenDiff(maxRow.row[j],
                    arrSlice[rowi][colj].toString)).join ~ arrSlice[rowi][colj].toString;

            if (truncate && enoughCols && (j == PrettyArrConfig.edgeItems))
            {
                newRow[$ - 1] = Frame.truncStr; // overwrite last with truncation string
            }
        }

        if (truncate && enoughRows)
        {
            if (i != PrettyArrConfig.edgeItems)
                arrStr ~= addedFrame ~ newRow.join(" ") ~ addedFrame ~ Frame.newline;
            else
                arrStr ~= addedFrame ~ (cast(string) Frame.truncStr)
                    .repeat(maxRow.strlen).join ~ addedFrame ~ Frame.newline;
        }
        else
        {
            arrStr ~= addedFrame ~ newRow.join(" ") ~ addedFrame ~ Frame.newline;
        }
    }
    return arrStr;
}

private string prettyFrame(T)(T arrSlice, string addedFrame, Tuple!(ulong,
        "strlen", string[], "row") maxRow, bool truncate)
        if (arrSlice.shape.length > 2)
{
    string arrStr;
    for (ulong i; i < arrSlice.shape[0]; i++)
    {
        string padding = getPadding!(typeof(arrSlice[i].shape))(arrSlice[i].shape, maxRow.strlen);
        arrStr ~= addedFrame ~ Frame.ltAngle ~ padding ~ Frame.rtAngle ~ addedFrame ~ Frame.newline;
        arrStr ~= prettyFrame!(typeof(arrSlice[i]))(arrSlice[i],
                addedFrame ~ Frame.vBar, maxRow, truncate);
        arrStr ~= addedFrame ~ Frame.lbAngle ~ padding ~ Frame.rbAngle ~ addedFrame ~ Frame.newline;
    }

    return arrStr;
}

// Check if an array can be truncated.
private bool canTruncate(T)(T arrSlice)
{
    return (arrSlice.flattened.length > PrettyArrConfig.threshold) || ((arrSlice.shape.length == 1)
            && (arrSlice.getStrLength > PrettyArrConfig.lineWidth)) ? true : false;
}

/++
Pretty-print D array.
+/
string prettyArr(T)(T arr)
in
{
    assert(isConvertibleToSlice!(typeof(arr)));
}
do
{
    string arrStr;
    auto arrSlice = arr.fuse; // convert to Mir Slice by GC allocating with fuse
    // check if we need array truncation
    const bool truncate = arrSlice.canTruncate;
    auto maxRow = arrSlice.getMaxStrLenAndMaxRow(truncate);
    string padding = getPadding!(typeof(arrSlice.shape))(arrSlice.shape, maxRow.strlen);
    arrStr ~= Frame.ltAngle ~ padding ~ Frame.rtAngle ~ Frame.newline;
    static if (arrSlice.shape.length > 1)
    {
        arrStr ~= prettyFrame!(typeof(arrSlice))(arrSlice, Frame.vBar, maxRow, truncate);
    }
    else
    {
        arrStr ~= prettyFrame!(typeof(arrSlice))(arrSlice, truncate);
    }
    arrStr ~= Frame.lbAngle ~ padding ~ Frame.rbAngle ~ Frame.newline;
    return arrStr;
}

unittest
{
    import std.range : chunks;

    // TODO: getShape tests

    int[] a0 = [200, 1, -3, 0, 0, 8501, 23];
    string testa0 = "┌                    ┐
│200 1 -3 0 0 8501 23│
└                    ┘
";
    assert(prettyArr!(typeof(a0))(a0) == testa0);

    auto a = [5, 2].iota!int(1).fuse;
    auto maxa = a.getMaxStrLenAndMaxRow(a.canTruncate);
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
    auto maxb = b.getMaxStrLenAndMaxRow(b.canTruncate);
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

    auto e = [2, 3, 6, 6].iota!int(1).fuse;
    string teste = "┌                           ┐
│┌                         ┐│
││┌                       ┐││
│││  1   2   3   4   5   6│││
│││  7   8   9  10  11  12│││
│││ 13  14  15  16  17  18│││
│││ 19  20  21  22  23  24│││
│││ 25  26  27  28  29  30│││
│││ 31  32  33  34  35  36│││
││└                       ┘││
││┌                       ┐││
│││ 37  38  39  40  41  42│││
│││ 43  44  45  46  47  48│││
│││ 49  50  51  52  53  54│││
│││ 55  56  57  58  59  60│││
│││ 61  62  63  64  65  66│││
│││ 67  68  69  70  71  72│││
││└                       ┘││
││┌                       ┐││
│││ 73  74  75  76  77  78│││
│││ 79  80  81  82  83  84│││
│││ 85  86  87  88  89  90│││
│││ 91  92  93  94  95  96│││
│││ 97  98  99 100 101 102│││
│││103 104 105 106 107 108│││
││└                       ┘││
│└                         ┘│
│┌                         ┐│
││┌                       ┐││
│││109 110 111 112 113 114│││
│││115 116 117 118 119 120│││
│││121 122 123 124 125 126│││
│││127 128 129 130 131 132│││
│││133 134 135 136 137 138│││
│││139 140 141 142 143 144│││
││└                       ┘││
││┌                       ┐││
│││145 146 147 148 149 150│││
│││151 152 153 154 155 156│││
│││157 158 159 160 161 162│││
│││163 164 165 166 167 168│││
│││169 170 171 172 173 174│││
│││175 176 177 178 179 180│││
││└                       ┘││
││┌                       ┐││
│││181 182 183 184 185 186│││
│││187 188 189 190 191 192│││
│││193 194 195 196 197 198│││
│││199 200 201 202 203 204│││
│││205 206 207 208 209 210│││
│││211 212 213 214 215 216│││
││└                       ┘││
│└                         ┘│
└                           ┘
";
    assert(e.prettyArr == teste);

    auto f = [210, 5].iota!int(1).fuse;
    string testf = "┌                        ┐
│   1    2    3    4    5│
│   6    7    8    9   10│
│  11   12   13   14   15│
│░░░░░░░░░░░░░░░░░░░░░░░░│
│1036 1037 1038 1039 1040│
│1041 1042 1043 1044 1045│
│1046 1047 1048 1049 1050│
└                        ┘
";
    assert(f.prettyArr == testf);

    auto g = [100, 100].iota!int(1).fuse;
    string testg = "┌                                ┐
│   1    2    3 ░   98   99   100│
│ 101  102  103 ░  198  199   200│
│ 201  202  203 ░  298  299   300│
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│9701 9702 9703 ░ 9798 9799  9800│
│9801 9802 9803 ░ 9898 9899  9900│
│9901 9902 9903 ░ 9998 9999 10000│
└                                ┘
";
    assert(g.prettyArr == testg);

    auto h = [500].iota!int(1).fuse;
    string testh = "┌                   ┐
│1 2 3 ░ 498 499 500│
└                   ┘
";
    assert(h.prettyArr == testh);

    auto i = [2, 100, 500].iota!int(1).fuse;
    string testi = "┌                                        ┐
│┌                                      ┐│
││    1     2     3 ░   498   499    500││
││  501   502   503 ░   998   999   1000││
││ 1001  1002  1003 ░  1498  1499   1500││
││░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░││
││48501 48502 48503 ░ 48998 48999  49000││
││49001 49002 49003 ░ 49498 49499  49500││
││49501 49502 49503 ░ 49998 49999  50000││
│└                                      ┘│
│┌                                      ┐│
││50001 50002 50003 ░ 50498 50499  50500││
││50501 50502 50503 ░ 50998 50999  51000││
││51001 51002 51003 ░ 51498 51499  51500││
││░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░││
││98501 98502 98503 ░ 98998 98999  99000││
││99001 99002 99003 ░ 99498 99499  99500││
││99501 99502 99503 ░ 99998 99999 100000││
│└                                      ┘│
└                                        ┘
";
    assert(i.prettyArr == testi);

    auto j = [[1.23, real.nan, 13.44], [real.infinity, real.infinity, -0.412]];
    PrettyArrConfig.suppressExp = false;
    string testj = "┌                              ┐
│1.230000e+00 nan  1.344000e+01│
│         inf inf -4.120000e-01│
└                              ┘
";
    assert(j.prettyArr == testj);

    auto k = [
        [0.000023, real.nan, 13.44], [real.infinity, real.infinity, -0.412]
    ];
    string testk = "┌                      ┐
│0.000023 nan 13.440000│
│     inf inf -0.412000│
└                      ┘
";
    PrettyArrConfig.suppressExp = true;
    assert(k.prettyArr == testk);

    auto l = [
        [0.000023, 1.234023, 13.443333], [479.311231, -100.001001, -0.412223]
    ];
    string testl = "┌                    ┐
│  0.00    1.23 13.44│
│479.31 -100.00 -0.41│
└                    ┘
";
    PrettyArrConfig.precision = 2;
    assert(l.prettyArr == testl);

}
