const std = @import("std");
const calculator = @import("calculator.zig");

const PlusTool = calculator.PlusTool;
const Result = PlusTool.Result;

// Test helper to compare results
fn expectResultEqual(expected: anytype, actual: Result) !void {
    const expected_type = @TypeOf(expected);
    switch (actual) {
        .value => |v| {
            if (expected_type == comptime_int) {
                try std.testing.expectEqual(@as(i64, @intCast(expected)), v);
            } else {
                unreachable;
            }
        },
        .err => |e| {
            // If we expected an error string
            if (expected_type == []const u8) {
                try std.testing.expectEqualStrings(expected, e);
            } else {
                std.debug.print("Expected value but got error: {s}\n", .{e});
                return error.UnexpectedResult;
            }
        },
    }
}

test "PlusTool: basic addition with positive numbers" {
    var plus_tool = PlusTool.init();
    
    const result1 = plus_tool.use("```plus 1 2```");
    try expectResultEqual(3, result1);
    
    const result2 = plus_tool.use("```plus 3 4```");
    try expectResultEqual(7, result2);
}

test "PlusTool: addition with negative numbers" {
    var plus_tool = PlusTool.init();
    
    const result1 = plus_tool.use("```plus -3 3```");
    try expectResultEqual(0, result1);
    
    const result2 = plus_tool.use("```plus -5 -3```");
    try expectResultEqual(-8, result2);
    
    const result3 = plus_tool.use("```plus 10 -15```");
    try expectResultEqual(-5, result3);
}

test "PlusTool: addition with zero" {
    var plus_tool = PlusTool.init();
    
    const result1 = plus_tool.use("```plus 0 0```");
    try expectResultEqual(0, result1);
    
    const result2 = plus_tool.use("```plus 5 0```");
    try expectResultEqual(5, result2);
    
    const result3 = plus_tool.use("```plus 0 5```");
    try expectResultEqual(5, result3);
}

test "PlusTool: large numbers" {
    var plus_tool = PlusTool.init();
    
    const result1 = plus_tool.use("```plus 1000000 2000000```");
    try expectResultEqual(3000000, result1);
    
    const result2 = plus_tool.use("```plus -1000000 1000000```");
    try expectResultEqual(0, result2);
}

test "PlusTool: syntax error - too many numbers" {
    var plus_tool = PlusTool.init();
    
    const result = plus_tool.use("```plus 1 2 3```");
    try expectResultEqual("SyntaxError: invalid syntax.", result);
}

test "PlusTool: syntax error - missing closing backticks" {
    var plus_tool = PlusTool.init();
    
    const result = plus_tool.use("```plus 1 2");
    try expectResultEqual("SyntaxError: invalid syntax.", result);
}

test "PlusTool: syntax error - no numbers provided" {
    var plus_tool = PlusTool.init();
    
    const result = plus_tool.use("```plus ```");
    try expectResultEqual("SyntaxError: invalid syntax.", result);
}

test "PlusTool: syntax error - only one number" {
    var plus_tool = PlusTool.init();
    
    const result = plus_tool.use("```plus 5```");
    try expectResultEqual("SyntaxError: invalid syntax.", result);
}

test "PlusTool: value error - non-numeric input" {
    var plus_tool = PlusTool.init();
    
    const result = plus_tool.use("```plus 1 a```");
    try expectResultEqual("ValueError: invalid value.", result);
}

test "PlusTool: value error - both inputs non-numeric" {
    var plus_tool = PlusTool.init();
    
    const result = plus_tool.use("```plus a b```");
    try expectResultEqual("ValueError: invalid value.", result);
}

test "PlusTool: value error - float numbers (not supported)" {
    var plus_tool = PlusTool.init();
    
    const result = plus_tool.use("```plus 1.5 2.5```");
    try expectResultEqual("ValueError: invalid value.", result);
}

test "PlusTool: extra whitespace handling" {
    var plus_tool = PlusTool.init();
    
    const result1 = plus_tool.use("```plus   1   2   ```");
    try expectResultEqual(3, result1);
    
    const result2 = plus_tool.use("```plus\t5\t3```");
    try expectResultEqual(8, result2);
}

test "PlusTool: missing action keyword" {
    var plus_tool = PlusTool.init();
    
    const result = plus_tool.use("1 2");
    try expectResultEqual("SyntaxError: invalid syntax.", result);
}

test "PlusTool: empty input" {
    var plus_tool = PlusTool.init();
    
    const result = plus_tool.use("");
    try expectResultEqual("SyntaxError: invalid syntax.", result);
}

test "PlusTool: mixed valid and invalid scenarios" {
    var plus_tool = PlusTool.init();
    
    // Valid cases
    try expectResultEqual(100, plus_tool.use("```plus 50 50```"));
    try expectResultEqual(-100, plus_tool.use("```plus -50 -50```"));
    try expectResultEqual(0, plus_tool.use("```plus -50 50```"));
    
    // Invalid cases
    try expectResultEqual("SyntaxError: invalid syntax.", plus_tool.use("```plus```"));
    try expectResultEqual("ValueError: invalid value.", plus_tool.use("```plus abc 123```"));
}
