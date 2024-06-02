const std = @import("std");
const p = @import("primitives.zig");
const eql = std.mem.eql;

pub fn parse(allocator: p.Allocator, args: []const p.str) !?Expression {
    if (args.len == 1) {
        return null;
    }
    return try parseOr(allocator, args, 1);
}

fn parseOr(allocator: p.Allocator, args: []const p.str, i: usize) !Expression {
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

fn parseAnd(allocator: p.Allocator, args: []const p.str, i: usize) !Expression {
    if (i >= args.len) return error.MissingAnd;

    var left = try parsePrimary(args, i);

    while (i + left.length < args.len and eql(u8, args[i + left.length], "-a")) {
        const pLeft = try allocator.create(Expression);
        pLeft.* = left;

        const pRight = try allocator.create(Expression);
        pRight.* = try parsePrimary(args, i + left.length + 1);

        left = Expression{
            .length = left.length + 1 + pRight.*.length,
            .value = .{ .op_a = .{
                .left = pLeft,
                .right = pRight,
            } },
        };
    }

    return left;
}

fn parsePrimary(args: []const p.str, i: usize) !Expression {
    if (i >= args.len) return error.MissingPrimary;

    return Expression{ .length = 1, .value = .{ .str = args[i] } };
}

pub const Expression = struct {
    length: usize,
    value: Value,

    pub fn prettyPrint(self: @This(), w: p.Writer, lvl: u64) p.Writer.Error!void {
        try indent(w, lvl);
        //try w.print("{d} ", .{self.length}); // display the length of each node
        try switch (self.value) {
            .fd => |v| printFd(w, 0, v),
            .file => |v| printFile(w, 0, v),
            .int => |v| printInt(w, 0, v),
            .op_a => |v| prettyPrintBinary(w, lvl, p.Expr, v, printExpr, "-a"),
            .op_b => |v| prettyPrintUnary(w, lvl, p.File, v, printFile, "-b"),
            .op_c => |v| prettyPrintUnary(w, lvl, p.File, v, printFile, "-c"),
            .op_d => |v| prettyPrintUnary(w, lvl, p.File, v, printFile, "-d"),
            .op_e => |v| prettyPrintUnary(w, lvl, p.File, v, printFile, "-e"),
            .op_ef => |v| prettyPrintBinary(w, lvl, p.File, v, printFile, "-ef"),
            .op_eq => |v| prettyPrintBinary(w, lvl, p.Int, v, printInt, "-eq"),
            .op_equal => |v| prettyPrintBinary(w, lvl, p.str, v, printStr, "="),
            .op_f => |v| prettyPrintUnary(w, lvl, p.File, v, printFile, "-f"),
            .op_g => |v| prettyPrintUnary(w, lvl, p.File, v, printFile, "-g"),
            .op_G => |v| prettyPrintUnary(w, lvl, p.File, v, printFile, "-G"),
            .op_ge => |v| prettyPrintBinary(w, lvl, p.Int, v, printInt, "-ge"),
            .op_gt => |v| prettyPrintBinary(w, lvl, p.Int, v, printInt, "-gt"),
            .op_h => |v| prettyPrintUnary(w, lvl, p.File, v, printFile, "-h"),
            .op_k => |v| prettyPrintUnary(w, lvl, p.File, v, printFile, "-k"),
            .op_L => |v| prettyPrintUnary(w, lvl, p.File, v, printFile, "-L"),
            .op_le => |v| prettyPrintBinary(w, lvl, p.Int, v, printInt, "-le"),
            .op_lt => |v| prettyPrintBinary(w, lvl, p.Int, v, printInt, "-lt"),
            .op_n => |v| prettyPrintUnary(w, lvl, p.File, v, printFile, "-n"),
            .op_N => |v| prettyPrintUnary(w, lvl, p.str, v, printStr, "-N"),
            .op_ne => |v| prettyPrintBinary(w, lvl, p.Int, v, printInt, "-ne"),
            .op_not_equal => |v| prettyPrintBinary(w, lvl, p.str, v, printStr, "!="),
            .op_nt => |v| prettyPrintBinary(w, lvl, p.File, v, printFile, "-nt"),
            .op_O => |v| prettyPrintUnary(w, lvl, p.File, v, printFile, "-O"),
            .op_o => |v| prettyPrintBinary(w, lvl, p.Expr, v, printExpr, "-o"),
            .op_ot => |v| prettyPrintBinary(w, lvl, p.File, v, printFile, "-ot"),
            .op_p => |v| prettyPrintUnary(w, lvl, p.File, v, printFile, "-p"),
            .op_r => |v| prettyPrintUnary(w, lvl, p.File, v, printFile, "-r"),
            .op_s => |v| prettyPrintUnary(w, lvl, p.File, v, printFile, "-s"),
            .op_S => |v| prettyPrintUnary(w, lvl, p.File, v, printFile, "-S"),
            .op_t => |v| prettyPrintUnary(w, lvl, p.Fd, v, printFd, "-t"),
            .op_u => |v| prettyPrintUnary(w, lvl, p.File, v, printFile, "-u"),
            .op_w => |v| prettyPrintUnary(w, lvl, p.File, v, printFile, "-w"),
            .op_x => |v| prettyPrintUnary(w, lvl, p.File, v, printFile, "-x"),
            .op_z => |v| prettyPrintUnary(w, lvl, p.str, v, printStr, "-z"),
            .str => |v| printStr(w, 0, v),
        };
    }

    fn indent(w: p.Writer, lvl: u64) p.Writer.Error!void {
        for (0..lvl * 2) |_| {
            try w.writeByte(' ');
        }
    }

    fn prettyPrintBinary(
        w: p.Writer,
        lvl: u64,
        comptime T: type,
        v: p.Binary(T),
        printer: fn (p.Writer, u64, T) p.Writer.Error!void,
        repr: p.str,
    ) !void {
        try printRepr(w, repr);
        try printer(w, lvl + 1, v.left);
        try printer(w, lvl + 1, v.right);
    }

    fn prettyPrintUnary(
        w: p.Writer,
        lvl: u64,
        comptime T: type,
        v: p.Unary(T),
        printer: fn (p.Writer, u64, T) p.Writer.Error!void,
        repr: p.str,
    ) !void {
        try printRepr(w, repr);
        try printer(w, lvl + 1, v.operand);
    }

    fn printRepr(w: p.Writer, repr: p.str) p.Writer.Error!void {
        try w.print("{s}\n", .{repr});
    }

    fn printInt(w: p.Writer, lvl: u64, val: p.Int) p.Writer.Error!void {
        switch (val) {
            .lit => |v| {
                try indent(w, lvl);
                try w.print("int: {d}\n", .{v});
            },
            .op_l => |v| {
                try prettyPrintUnary(w, lvl, p.str, v, printStr, "-l");
            },
        }
    }

    fn printFd(w: p.Writer, lvl: u64, v: p.Fd) p.Writer.Error!void {
        try indent(w, lvl);
        try w.print("fd: {d}\n", .{v});
    }

    fn printFile(w: p.Writer, lvl: u64, v: p.File) p.Writer.Error!void {
        try indent(w, lvl);
        try w.print("file: {s}\n", .{v});
    }

    fn printStr(w: p.Writer, lvl: u64, v: p.str) p.Writer.Error!void {
        try indent(w, lvl);
        try w.print("str: {s}\n", .{v});
    }

    fn printExpr(w: p.Writer, lvl: u64, v: p.Expr) p.Writer.Error!void {
        try v.*.prettyPrint(w, lvl);
    }

    const Value = union(enum) {
        fd: p.Fd,
        file: p.str,
        int: p.Int,
        op_a: p.Binary(p.Expr),
        op_b: p.Unary(p.File),
        op_c: p.Unary(p.File),
        op_d: p.Unary(p.File),
        op_e: p.Unary(p.File),
        op_ef: p.Binary(p.File),
        op_eq: p.Binary(p.Int),
        op_equal: p.Binary(p.str),
        op_f: p.Unary(p.File),
        op_g: p.Unary(p.File),
        op_G: p.Unary(p.File),
        op_ge: p.Binary(p.Int),
        op_gt: p.Binary(p.Int),
        op_h: p.Unary(p.File),
        op_k: p.Unary(p.File),
        op_L: p.Unary(p.File),
        op_le: p.Binary(p.Int),
        op_lt: p.Binary(p.Int),
        op_N: p.Unary(p.File),
        op_n: p.Unary(p.str),
        op_ne: p.Binary(p.Int),
        op_not_equal: p.Binary(p.str),
        op_nt: p.Binary(p.File),
        op_o: p.Binary(p.Expr),
        op_O: p.Unary(p.File),
        op_ot: p.Binary(p.File),
        op_p: p.Unary(p.File),
        op_r: p.Unary(p.File),
        op_s: p.Unary(p.File),
        op_S: p.Unary(p.File),
        op_t: p.Unary(p.Fd),
        op_u: p.Unary(p.File),
        op_w: p.Unary(p.File),
        op_x: p.Unary(p.File),
        op_z: p.Unary(p.str),
        str: p.str,
    };
};
