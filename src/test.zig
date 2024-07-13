const std = @import("std");
const unit = std.testing;

const p = @import("primitives.zig");
const main = @import("main.zig");

const prog = "ztest";

// Fundamentals

test "1a" {
    try ztest(&.{}, .{ .exit_code = 1 }, .{});
}
test "1b" {
    try ztest(&[_]p.str{ "-z", "" }, .{}, .{ .neg = true, .paren = true });
}
test "1c" {
    try ztest(&[_]p.str{"any-string"}, .{}, .{ .neg = true, .paren = true });
}
test "1d" {
    try ztest(&[_]p.str{ "-n", "any-string" }, .{}, .{ .neg = true, .paren = true });
}
test "1e" {
    try ztest(&[_]p.str{""}, .{ .exit_code = 1 }, .{ .neg = true, .paren = true });
}
test "1f" {
    try ztest(&[_]p.str{"-"}, .{}, .{ .neg = true, .paren = true });
}
test "1g" {
    try ztest(&[_]p.str{"--"}, .{}, .{ .neg = true, .paren = true });
}
test "1h" {
    try ztest(&[_]p.str{"-0"}, .{}, .{ .neg = true, .paren = true });
}
test "1i" {
    try ztest(&[_]p.str{"-f"}, .{}, .{ .neg = true, .paren = true });
}
test "1j" {
    try ztest(&[_]p.str{"--help"}, .{}, .{ .neg = true, .paren = true });
}
test "1k" {
    try ztest(&[_]p.str{"--version"}, .{}, .{ .neg = true, .paren = true });
}

// String equality

test "streq-1" {
    try ztest(&[_]p.str{ "t", "=", "t" }, .{}, .{ .neg = true, .paren = true });
}
test "streq-2" {
    try ztest(&[_]p.str{ "t", "=", "f" }, .{ .exit_code = 1 }, .{ .neg = true, .paren = true });
}
test "streqeq-1" {
    try ztest(&[_]p.str{ "t", "==", "t" }, .{}, .{ .neg = true, .paren = true });
}
test "streqeq-2" {
    try ztest(&[_]p.str{ "t", "==", "f" }, .{ .exit_code = 1 }, .{ .neg = true, .paren = true });
}
test "streq-3" {
    try ztest(&[_]p.str{ "!", "=", "!" }, .{}, .{ .neg = true, .paren = true });
}
test "streq-4" {
    try ztest(&[_]p.str{ "=", "=", "=" }, .{}, .{ .neg = true, .paren = true });
}
test "streq-5" {
    try ztest(&[_]p.str{ "(", "=", "(" }, .{}, .{ .neg = true });
}
test "streq-6" {
    try ztest(&[_]p.str{ "(", "=", ")" }, .{ .exit_code = 1 }, .{ .neg = true });
}
test "strne-1" {
    try ztest(&[_]p.str{ "t", "!=", "t" }, .{ .exit_code = 1 }, .{ .neg = true, .paren = true });
}
test "strne-2" {
    try ztest(&[_]p.str{ "t", "!=", "f" }, .{}, .{ .neg = true, .paren = true });
}
test "strne-3" {
    try ztest(&[_]p.str{ "!", "!=", "!" }, .{ .exit_code = 1 }, .{ .neg = true, .paren = true });
}
test "strne-4" {
    try ztest(&[_]p.str{ "=", "!=", "=" }, .{ .exit_code = 1 }, .{ .neg = true, .paren = true });
}
test "strne-5" {
    try ztest(&[_]p.str{ "(", "!=", "(" }, .{ .exit_code = 1 }, .{ .neg = true, .paren = true });
}
test "strne-6" {
    try ztest(&[_]p.str{ "(", "!=", ")" }, .{}, .{ .neg = true });
}

// Logical conjunction

test "and-1" {
    try ztest(&[_]p.str{ "t", "-a", "t" }, .{}, .{ .neg = true, .paren = true });
}
test "and-2" {
    try ztest(&[_]p.str{ "", "-a", "-t" }, .{ .exit_code = 1 }, .{ .neg = true, .paren = true });
}
test "and-3" {
    try ztest(&[_]p.str{ "t", "-a", "" }, .{ .exit_code = 1 }, .{ .neg = true, .paren = true });
}
test "and-4" {
    try ztest(&[_]p.str{ "", "-a", "" }, .{ .exit_code = 1 }, .{ .neg = true, .paren = true });
}

// Logical disjunction

test "or-1" {
    try ztest(&[_]p.str{ "t", "-o", "t" }, .{}, .{ .neg = true, .paren = true });
}
test "or-2" {
    try ztest(&[_]p.str{ "", "-o", "-t" }, .{}, .{ .neg = true, .paren = true });
}
test "or-3" {
    try ztest(&[_]p.str{ "t", "-o", "" }, .{}, .{ .neg = true, .paren = true });
}
test "or-4" {
    try ztest(&[_]p.str{ "", "-o", "" }, .{ .exit_code = 1 }, .{ .neg = true, .paren = true });
}

// Integer equality

test "eq-1" {
    try ztest(&[_]p.str{ "9", "-eq", "9" }, .{}, .{ .neg = true, .paren = true });
}
test "eq-2" {
    try ztest(&[_]p.str{ "0", "-eq", "0" }, .{}, .{ .neg = true, .paren = true });
}
test "eq-3" {
    try ztest(&[_]p.str{ "0", "-eq", "00" }, .{}, .{ .neg = true, .paren = true });
}
test "eq-4" {
    try ztest(&[_]p.str{ "8", "-eq", "9" }, .{ .exit_code = 1 }, .{ .neg = true, .paren = true });
}
test "eq-5" {
    try ztest(&[_]p.str{ "1", "-eq", "0" }, .{ .exit_code = 1 }, .{ .neg = true, .paren = true });
}
test "eq-6" {
    try ztest(&[_]p.str{ UINTMAX_OFLOW, "-eq", "0" }, .{ .exit_code = 1 }, .{ .neg = true, .paren = true });
}

// Greater than

test "gt-1" {
    try ztest(&[_]p.str{ "5", "-gt", "5" }, .{ .exit_code = 1 }, .{ .neg = true, .paren = true, .inv = true });
}
test "gt-2" {
    try ztest(&[_]p.str{ "5", "-gt", "4" }, .{}, .{ .neg = true, .paren = true, .inv = true });
}
test "gt-3" {
    try ztest(&[_]p.str{ "4", "-gt", "5" }, .{ .exit_code = 1 }, .{ .neg = true, .paren = true, .inv = true });
}
test "gt-4" {
    try ztest(&[_]p.str{ "-1", "-gt", "-2" }, .{}, .{ .neg = true, .paren = true, .inv = true });
}
test "gt-5" {
    try ztest(&[_]p.str{ UINTMAX_OFLOW, "-gt", INTMAX_UFLOW }, .{}, .{ .neg = true, .paren = true, .inv = true });
}

// Less than

test "lt-1" {
    try ztest(&[_]p.str{ "5", "-lt", "5" }, .{ .exit_code = 1 }, .{ .neg = true, .paren = true, .inv = true });
}
test "lt-2" {
    try ztest(&[_]p.str{ "5", "-lt", "4" }, .{ .exit_code = 1 }, .{ .neg = true, .paren = true, .inv = true });
}
test "lt-3" {
    try ztest(&[_]p.str{ "4", "-lt", "5" }, .{}, .{ .neg = true, .paren = true, .inv = true });
}
test "lt-4" {
    try ztest(&[_]p.str{ "-1", "-lt", "-2" }, .{ .exit_code = 1 }, .{ .neg = true, .paren = true, .inv = true });
}
test "lt-5" {
    try ztest(&[_]p.str{ INTMAX_UFLOW, "-lt", UINTMAX_OFLOW }, .{}, .{ .neg = true, .paren = true, .inv = true });
}

// Invalid

test "inv-1" {
    const inv = "0x0";
    try ztest(&[_]p.str{ inv, "-eq", "00" }, .{
        .exit_code = 2,
        .stderr = prog ++ ": invalid integer '" ++ inv ++ "'",
    }, .{ .neg = true, .paren = true });
}

// -t

test "t1" {
    try ztest(&[_]p.str{"-t"}, .{}, .{ .neg = true, .paren = true });
}

test "t2" {
    try ztest(&[_]p.str{ "-t", "3" }, .{ .exit_code = 1 }, .{ .neg = true, .paren = true });
}

// groupings

test "paren-1" {
    try ztest(&[_]p.str{ "(", "", ")" }, .{ .exit_code = 1 }, .{ .neg = true });
}
test "paren-2" {
    try ztest(&[_]p.str{ "(", "(", ")" }, .{}, .{ .neg = true });
}
test "paren-3" {
    try ztest(&[_]p.str{ "(", ")", ")" }, .{}, .{ .neg = true });
}
test "paren-4" {
    try ztest(&[_]p.str{ "(", "!", ")" }, .{}, .{ .neg = true });
}
test "paren-5" {
    try ztest(&[_]p.str{ "(", "-a", ")" }, .{}, .{ .neg = true });
}

const INTMAX_OFLOW = int2str(std.math.maxInt(c_int) + 1);
const INTMAX_UFLOW = int2str(std.math.minInt(c_int) - 1);
const UINTMAX_OFLOW = int2str(std.math.maxInt(c_uint) + 1);
const UINTMAX_UFLOW = int2str(std.math.minInt(c_uint) - 1);

const Options = packed struct {
    /// The test can be negated
    neg: bool = false,
    /// The test can be parenthesized
    paren: bool = false,
    /// The test can be inverted (useful for comparisons)
    inv: bool = false,
};

fn ztest(comptime args: p.Args, expected: Result, comptime opts: Options) !void {
    // test normal case
    try run(args, expected);

    if (opts.inv) {
        const op = args[1];
        const inv_op: ?p.str = comptime (if (p.streq(op, "-eq")) "-ne" //
        else if (p.streq(op, "-lt")) "-ge" //
        else if (p.streq(op, "-gt")) "-le" //
        else null);

        if (inv_op) |inv| {
            try run(
                &[_]p.str{ args[0], inv, args[2] },
                expected.withInvertedExitCode(),
            );
        }
    }

    if (opts.neg) {
        // negated
        try run(&[_]p.str{"!"} ++ args, expected.withInvertedExitCode());
    }

    if (opts.paren) {
        // parenthesized
        try run(&[_]p.str{"("} ++ args ++ &[_]p.str{")"}, expected);
        // negated + parenthesized
        try run(&[_]p.str{ "!", "(" } ++ args ++ &[_]p.str{")"}, expected.withInvertedExitCode());
        // negated 2x + parenthesized
        try run(&[_]p.str{ "!", "!", "(" } ++ args ++ &[_]p.str{")"}, expected);
    }
}

fn run(comptime args_: p.Args, expected_: Result) !void {
    try unit.checkAllAllocationFailures(unit.allocator, struct {
        pub fn run(allocator: p.Allocator, args: p.Args, expected: Result) !void {
            var stderr = std.ArrayList(u8).init(allocator);
            defer stderr.deinit();

            try unit.expectEqual(expected.exit_code, try main.run(
                stderr.writer().any(),
                args,
                allocator,
            ));
            try unit.expectEqualStrings(expected.stderr, stderr.items);
        }
    }.run, .{ &[_]p.str{prog} ++ args_, expected_ });
}

const Result = struct {
    exit_code: u8 = 0,
    stderr: p.str = "",

    pub fn withInvertedExitCode(self: @This()) Result {
        return Result{
            .exit_code = if (self.exit_code < 2) 1 - self.exit_code else self.exit_code,
            .stderr = self.stderr,
        };
    }
};

fn int2str(comptime int: comptime_int) []const u8 {
    return std.fmt.comptimePrint("{}", .{int});
}
