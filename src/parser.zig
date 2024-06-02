const std = @import("std");

const eql = std.mem.eql;
const str = []const u8;
const Allocator = std.mem.Allocator;

pub fn parse(allocator: Allocator, args: []const str) !?Expression {
    if (args.len == 1) {
        return null;
    }
    return try parseOr(allocator, args, 1);
}

fn parseOr(allocator: Allocator, args: []const str, i: usize) !Expression {
    if (i >= args.len) return error.MissingOr;

    var left = try parseAnd(allocator, args, i);

    while (i + left.length < args.len and eql(u8, args[i + left.length], "-o")) {
        const pLeft = try allocator.create(Expression);
        pLeft.* = left;

        const pRight = try allocator.create(Expression);
        pRight.* = try parseAnd(allocator, args, i + left.length + 1);

        left = Expression{
            .length = left.length + 1 + pRight.*.length,
            .value = .{ .op_o = .{
                .left = pLeft,
                .right = pRight,
            } },
        };
    }

    return left;
}

fn parseAnd(allocator: Allocator, args: []const str, i: usize) !Expression {
    if (i >= args.len) return error.MissingAnd;

    var left = try parsePrimary(args, i);

    while (i + left.length < args.len and eql(u8, args[i + left.length], "-a")) {
        const pLeft = try allocator.create(Expression);
        pLeft.* = left;

        const pRight = try allocator.create(Expression);
        pRight.* = try parsePrimary(args, i + left.length + 1);

        left = Expression{
            .length = left.length + 1 + pRight.*.length,
            .value = .{ .op_o = .{
                .left = pLeft,
                .right = pRight,
            } },
        };
    }

    return left;
}

fn parsePrimary(args: []const str, i: usize) !Expression {
    if (i >= args.len) return error.MissingPrimary;

    return Expression{ .length = 1, .value = .{ .str = args[i] } };
}

pub const Expression = struct {
    length: usize,
    value: Value,

    const Expr = *const Expression;
    const Int = union(enum) {
        lit: i64,
        op_l: Unary(str),
    };
    const Fd = u32;
    const File = str;

    fn Unary(comptime T: type) type {
        return struct {
            operand: T,
        };
    }

    fn Binary(comptime T: type) type {
        return struct {
            left: T,
            right: T,
        };
    }

    const Writer = std.fs.File.Writer;

    pub fn prettyPrint(self: @This(), w: Writer) Writer.Error!void {
        try self.prettyPrintRec(w, 0);
    }

    fn indent(w: Writer, lvl: u64) Writer.Error!void {
        for (0..lvl * 2) |_| {
            try w.writeByte(' ');
        }
    }

    pub fn prettyPrintRec(self: @This(), w: Writer, lvl: u64) Writer.Error!void {
        try indent(w, lvl);
        //try w.print("{d} ", .{self.length}); // display the length of each node
        try switch (self.value) {
            .fd => |v| printFd(w, 0, v),
            .file => |v| printFile(w, 0, v),
            .int => |v| printInt(w, 0, v),
            .op_a => |v| prettyPrintBinary(w, lvl, Expr, v, printExpr, "-a"),
            .op_b => |v| prettyPrintUnary(w, lvl, File, v, printFile, "-b"),
            .op_c => |v| prettyPrintUnary(w, lvl, File, v, printFile, "-c"),
            .op_d => |v| prettyPrintUnary(w, lvl, File, v, printFile, "-d"),
            .op_e => |v| prettyPrintUnary(w, lvl, File, v, printFile, "-e"),
            .op_ef => |v| prettyPrintBinary(w, lvl, File, v, printFile, "-ef"),
            .op_eq => |v| prettyPrintBinary(w, lvl, Int, v, printInt, "-eq"),
            .op_equal => |v| prettyPrintBinary(w, lvl, str, v, printStr, "="),
            .op_f => |v| prettyPrintUnary(w, lvl, File, v, printFile, "-f"),
            .op_g => |v| prettyPrintUnary(w, lvl, File, v, printFile, "-g"),
            .op_G => |v| prettyPrintUnary(w, lvl, File, v, printFile, "-G"),
            .op_ge => |v| prettyPrintBinary(w, lvl, Int, v, printInt, "-ge"),
            .op_gt => |v| prettyPrintBinary(w, lvl, Int, v, printInt, "-gt"),
            .op_h => |v| prettyPrintUnary(w, lvl, File, v, printFile, "-h"),
            .op_k => |v| prettyPrintUnary(w, lvl, File, v, printFile, "-k"),
            .op_L => |v| prettyPrintUnary(w, lvl, File, v, printFile, "-L"),
            .op_le => |v| prettyPrintBinary(w, lvl, Int, v, printInt, "-le"),
            .op_lt => |v| prettyPrintBinary(w, lvl, Int, v, printInt, "-lt"),
            .op_n => |v| prettyPrintUnary(w, lvl, File, v, printFile, "-n"),
            .op_N => |v| prettyPrintUnary(w, lvl, str, v, printStr, "-N"),
            .op_ne => |v| prettyPrintBinary(w, lvl, Int, v, printInt, "-ne"),
            .op_not_equal => |v| prettyPrintBinary(w, lvl, str, v, printStr, "!="),
            .op_nt => |v| prettyPrintBinary(w, lvl, File, v, printFile, "-nt"),
            .op_O => |v| prettyPrintUnary(w, lvl, File, v, printFile, "-O"),
            .op_o => |v| prettyPrintBinary(w, lvl, Expr, v, printExpr, "-o"),
            .op_ot => |v| prettyPrintBinary(w, lvl, File, v, printFile, "-ot"),
            .op_p => |v| prettyPrintUnary(w, lvl, File, v, printFile, "-p"),
            .op_r => |v| prettyPrintUnary(w, lvl, File, v, printFile, "-r"),
            .op_s => |v| prettyPrintUnary(w, lvl, File, v, printFile, "-s"),
            .op_S => |v| prettyPrintUnary(w, lvl, File, v, printFile, "-S"),
            .op_t => |v| prettyPrintUnary(w, lvl, Fd, v, printFd, "-t"),
            .op_u => |v| prettyPrintUnary(w, lvl, File, v, printFile, "-u"),
            .op_w => |v| prettyPrintUnary(w, lvl, File, v, printFile, "-w"),
            .op_x => |v| prettyPrintUnary(w, lvl, File, v, printFile, "-x"),
            .op_z => |v| prettyPrintUnary(w, lvl, str, v, printStr, "-z"),
            .str => |v| printStr(w, 0, v),
        };
    }

    fn prettyPrintBinary(
        w: Writer,
        lvl: u64,
        comptime T: type,
        v: Binary(T),
        printer: fn (Writer, u64, T) Writer.Error!void,
        repr: str,
    ) !void {
        try printRepr(w, repr);
        try printer(w, lvl + 1, v.left);
        try printer(w, lvl + 1, v.right);
    }

    fn prettyPrintUnary(
        w: Writer,
        lvl: u64,
        comptime T: type,
        v: Unary(T),
        printer: fn (Writer, u64, T) Writer.Error!void,
        repr: str,
    ) !void {
        try printRepr(w, repr);
        try printer(w, lvl + 1, v.operand);
    }

    fn printRepr(w: Writer, repr: str) Writer.Error!void {
        try w.print("{s}\n", .{repr});
    }

    fn printInt(w: Writer, lvl: u64, val: Int) Writer.Error!void {
        switch (val) {
            .lit => |v| {
                try indent(w, lvl);
                try w.print("int: {d}\n", .{v});
            },
            .op_l => |v| {
                try prettyPrintUnary(w, lvl, str, v, printStr, "-l");
            },
        }
    }

    fn printFd(w: Writer, lvl: u64, v: Fd) Writer.Error!void {
        try indent(w, lvl);
        try w.print("fd: {d}\n", .{v});
    }

    fn printFile(w: Writer, lvl: u64, v: File) Writer.Error!void {
        try indent(w, lvl);
        try w.print("file: {s}\n", .{v});
    }

    fn printStr(w: Writer, lvl: u64, v: str) Writer.Error!void {
        try indent(w, lvl);
        try w.print("str: {s}\n", .{v});
    }

    fn printExpr(w: Writer, lvl: u64, v: Expr) Writer.Error!void {
        try v.*.prettyPrintRec(w, lvl);
    }

    const Value = union(enum) {
        fd: Fd,
        file: str,
        int: Int,
        op_a: Binary(Expr),
        op_b: Unary(File),
        op_c: Unary(File),
        op_d: Unary(File),
        op_e: Unary(File),
        op_ef: Binary(File),
        op_eq: Binary(Int),
        op_equal: Binary(str),
        op_f: Unary(File),
        op_g: Unary(File),
        op_G: Unary(File),
        op_ge: Binary(Int),
        op_gt: Binary(Int),
        op_h: Unary(File),
        op_k: Unary(File),
        op_L: Unary(File),
        op_le: Binary(Int),
        op_lt: Binary(Int),
        op_N: Unary(File),
        op_n: Unary(str),
        op_ne: Binary(Int),
        op_not_equal: Binary(str),
        op_nt: Binary(File),
        op_o: Binary(Expr),
        op_O: Unary(File),
        op_ot: Binary(File),
        op_p: Unary(File),
        op_r: Unary(File),
        op_s: Unary(File),
        op_S: Unary(File),
        op_t: Unary(Fd),
        op_u: Unary(File),
        op_w: Unary(File),
        op_x: Unary(File),
        op_z: Unary(str),
        str: str,
    };
};
