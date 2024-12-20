const std = @import("std");
const p = @import("primitives.zig");

const CriticalError = p.Allocator.Error;

pub const Error = CriticalError || error{
    InvalidInt,
    InvalidFd,
    ArgumentMissing,
};

/// Optional diagnostics used for reporting useful errors
pub const Diagnostic = struct {
    arg: ?p.str = undefined,

    pub fn report(self: @This(), out: p.Writer, err: Error) !void {
        switch (err) {
            error.ArgumentMissing => try out.writeAll("argument expected"),
            error.InvalidInt => try out.print("invalid integer '{s}'", .{self.arg orelse ""}),
            error.InvalidFd => try out.print("invalid file descriptor '{s}'", .{self.arg orelse ""}),
            else => try out.print("error parsing argument '{s}': {}", .{ self.arg orelse "", err }),
        }
    }
};

pub const Parser = struct {
    allocator: p.Allocator,
    diag: *Diagnostic,

    /// Initialize a Parser.
    pub fn init(allocator: p.Allocator, diag: *Diagnostic) Parser {
        return Parser{
            .allocator = allocator,
            .diag = diag,
        };
    }

    /// Must be called when an error is created and returned (return error.*)
    fn err(self: @This(), err_: anytype, arg: ?p.str) @TypeOf(err_) {
        self.diag.* = .{ .arg = arg };
        return err_;
    }

    /// Parse an expression.
    pub fn parse(self: @This(), args: p.Args) Error!?ParseResult(Expression) {
        return self.parseNegation(args);
    }

    fn parseNegation(self: @This(), args: p.Args) Error!?ParseResult(Expression) {
        if (p.indexes(0, args) and p.streq(args[0], "!")) {
            const right = try self.parseNegation(args[1..]) orelse return Error.ArgumentMissing;
            return ParseResult(Expression){
                .length = 1 + right.length,
                .value = @unionInit(Expression, "op_bang", try p.create(self.allocator, right.value)),
            };
        }
        return self.parseOr(args);
    }

    /// Parse logical disjunction expression.
    fn parseOr(self: @This(), args: p.Args) Error!?ParseResult(Expression) {
        return self.parseBinaryExpression(args, "-o", "op_o", parseAnd);
    }

    /// Parse logical conjunction expression.
    fn parseAnd(self: @This(), args: p.Args) Error!?ParseResult(Expression) {
        return self.parseBinaryExpression(args, "-a", "op_a", parsePrimary);
    }

    /// Parse a primary expression.
    fn parsePrimary(self: @This(), args: p.Args) Error!?ParseResult(Expression) {
        return try self.parseBracketed(args) //
        orelse try self.parseBinary(args, "-ef", "op_ef", operandString) //
        orelse try self.parseBinary(args, "-eq", "op_eq", operandInt) //
        orelse try self.parseBinary(args, "-ge", "op_ge", operandInt) //
        orelse try self.parseBinary(args, "-gt", "op_gt", operandInt) //
        orelse try self.parseBinary(args, "-le", "op_le", operandInt) //
        orelse try self.parseBinary(args, "-lt", "op_lt", operandInt) //
        orelse try self.parseBinary(args, "-ne", "op_ne", operandInt) //
        orelse try self.parseBinary(args, "-nt", "op_nt", operandString) //
        orelse try self.parseBinary(args, "-ot", "op_ot", operandString) //
        orelse try self.parseBinary(args, "!=", "op_bang_equal", operandString) //
        orelse try self.parseBinary(args, "=", "op_equal", operandString) //
        orelse try self.parseBinary(args, "==", "op_equal", operandString) // non-standard but still supported
        // Parsed binary before unary for maximum munch
        orelse try self.parseUnary(args, "-b", "op_b", operandString) //
        orelse try self.parseUnary(args, "-c", "op_c", operandString) //
        orelse try self.parseUnary(args, "-d", "op_d", operandString) //
        orelse try self.parseUnary(args, "-e", "op_e", operandString) //
        orelse try self.parseUnary(args, "-f", "op_f", operandString) //
        orelse try self.parseUnary(args, "-g", "op_g", operandString) //
        orelse try self.parseUnary(args, "-G", "op_G", operandString) //
        orelse try self.parseUnary(args, "-h", "op_h", operandString) //
        orelse try self.parseUnary(args, "-k", "op_k", operandString) //
        orelse try self.parseUnary(args, "-L", "op_L", operandString) //
        orelse try self.parseUnary(args, "-n", "op_n", operandString) //
        orelse try self.parseUnary(args, "-N", "op_N", operandString) //
        orelse try self.parseUnary(args, "-O", "op_O", operandString) //
        orelse try self.parseUnary(args, "-p", "op_p", operandString) //
        orelse try self.parseUnary(args, "-r", "op_r", operandString) //
        orelse try self.parseUnary(args, "-s", "op_s", operandString) //
        orelse try self.parseUnary(args, "-S", "op_S", operandString) //
        orelse try self.parseUnary(args, "-t", "op_t", operandFd) //
        orelse try self.parseUnary(args, "-u", "op_u", operandString) //
        orelse try self.parseUnary(args, "-w", "op_w", operandString) //
        orelse try self.parseUnary(args, "-x", "op_x", operandString) //
        orelse try self.parseUnary(args, "-z", "op_z", operandString) //
        orelse {
            if (self.parseInt(args)) |int| {
                return ParseResult(Expression){
                    .length = 1,
                    .value = .{ .int = int.value },
                };
            } else |_| if (p.indexes(0, args)) {
                return ParseResult(Expression){
                    .length = 1,
                    .value = .{ .str = args[0] },
                };
            }
            return null;
        };
    }

    fn parseBracketed(self: @This(), args: p.Args) Error!?ParseResult(Expression) {
        if (p.indexes(2, args) and p.streq(args[0], "(")) {
            if (p.streq(args[2], ")")) {
                if (try self.parseBinary(args, "=", "op_equal", operandString)) |streq| {
                    return streq;
                }
            }

            if (try self.parse(args[1..])) |inner| {
                if (p.indexes(1 + inner.length, args) and p.streq(args[1 + inner.length], ")")) {
                    return inner;
                }
            }
        }

        return null;
    }

    /// Parse a left-associative binary expression by recursive descent.
    fn parseBinaryExpression(
        self: @This(),
        args: p.Args,
        comptime operator: p.str,
        comptime field: p.str,
        descent_parser: fn (@This(), p.Args) Error!?ParseResult(Expression),
    ) Error!?ParseResult(Expression) {
        var left = try descent_parser(self, args) orelse return null;
        while (p.indexes(left.length, args) and p.streq(args[left.length], operator)) {
            const right = try descent_parser(self, args[left.length + 1 ..]) orelse return left;
            left = ParseResult(Expression){
                .length = left.length + 1 + right.length,
                .value = @unionInit(Expression, field, Binary(p.Expr){
                    .left = try p.create(self.allocator, left.value),
                    .right = try p.create(self.allocator, right.value),
                }),
            };
        }
        return left;
    }

    /// Parse a binary operation.
    fn parseBinary(
        self: @This(),
        args: p.Args,
        comptime operator: p.str,
        comptime field: p.str,
        comptime parse_operand: anytype,
    ) Error!?ParseResult(Expression) {
        const left_e = parse_operand(self, args);
        const iOperator = if (left_e) |v| v.length else |_| 1;
        if (!p.indexes(iOperator, args) or !p.streq(args[iOperator], operator)) {
            return null;
        }
        const left = try left_e;
        const right = try parse_operand(self, args[iOperator + 1 ..]);

        return ParseResult(Expression){ .length = left.length + 1 + right.length, .value = @unionInit(Expression, field, Binary(parseOperandValueType(parse_operand)){
            .left = left.value,
            .right = right.value,
        }) };
    }

    /// Parse an unary operation.
    fn parseUnary(
        self: @This(),
        args: p.Args,
        comptime operator: p.str,
        comptime field: p.str,
        comptime parse_operand: anytype,
    ) Error!?ParseResult(Expression) {
        if (p.indexes(0, args) and p.streq(operator, args[0])) {
            const arg = parse_operand(self, args[1..]) catch |e|
                return if (p.errorSetContains(CriticalError, e)) e else null;
            return ParseResult(Expression){ .length = 1 + arg.length, .value = @unionInit(Expression, field, arg.value) };
        }
        return null;
    }

    /// Expect a string operand.
    fn operandString(self: @This(), args: p.Args) Error!ParseResult(p.str) {
        return if (p.indexes(0, args))
            ParseResult(p.str){ .length = 1, .value = args[0] }
        else
            self.err(error.ArgumentMissing, null);
    }

    /// Expect an integer operand.
    fn operandInt(self: @This(), args: p.Args) Error!ParseResult(p.Int) {
        const int = try self.parseInt(args);
        return ParseResult(p.Int){ .length = int.length, .value = int.value };
    }

    /// Expect a file descriptor operand.
    fn operandFd(self: @This(), args: p.Args) Error!ParseResult(p.Fd) {
        const fd = try self.parseFd(args);
        return ParseResult(p.Fd){ .length = fd.length, .value = fd.value };
    }

    /// Parse a file descriptor.
    fn parseFd(self: @This(), args: p.Args) Error!ParseResult(p.Fd) {
        return if (p.indexes(0, args))
            ParseResult(p.Fd){
                .length = 1,
                .value = std.fmt.parseInt(p.Fd, args[0], 10) catch return error.InvalidFd,
            }
        else
            self.err(error.ArgumentMissing, null);
    }

    /// Parse an integer.
    fn parseInt(self: @This(), args: p.Args) Error!ParseResult(p.Int) {
        return if (!p.indexes(0, args))
            self.err(error.ArgumentMissing, null)
        else if (std.fmt.parseInt(p.Int, args[0], 10)) |lit|
            ParseResult(p.Int){ .length = 1, .value = lit }
        else |_| if (p.streq(args[0], "-l") and p.indexes(1, args))
            ParseResult(p.Int){ .length = 2, .value = @intCast(args[1].len) }
        else
            return self.err(error.InvalidInt, args[0]);
    }

    fn parseOperandValueType(parse_operand: anytype) type {
        return @typeInfo(@typeInfo(@typeInfo(@TypeOf(parse_operand))
            .@"fn".return_type.?) //
            .error_union.payload) //
            .@"struct".fields[1].type;
    }
};

pub const Expression = union(enum) {
    int: p.Int,
    op_a: Binary(p.Expr),
    op_b: Unary(p.str),
    op_bang: Unary(p.Expr),
    op_bang_equal: Binary(p.str),
    op_c: Unary(p.str),
    op_d: Unary(p.str),
    op_e: Unary(p.str),
    op_ef: Binary(p.str),
    op_eq: Binary(p.Int),
    op_equal: Binary(p.str),
    op_f: Unary(p.str),
    op_g: Unary(p.str),
    op_G: Unary(p.str),
    op_ge: Binary(p.Int),
    op_gt: Binary(p.Int),
    op_h: Unary(p.str),
    op_k: Unary(p.str),
    op_L: Unary(p.str),
    op_le: Binary(p.Int),
    op_lt: Binary(p.Int),
    op_N: Unary(p.str),
    op_n: Unary(p.str),
    op_ne: Binary(p.Int),
    op_nt: Binary(p.str),
    op_o: Binary(p.Expr),
    op_O: Unary(p.str),
    op_ot: Binary(p.str),
    op_p: Unary(p.str),
    op_r: Unary(p.str),
    op_s: Unary(p.str),
    op_S: Unary(p.str),
    op_t: Unary(p.Fd),
    op_u: Unary(p.str),
    op_w: Unary(p.str),
    op_x: Unary(p.str),
    op_z: Unary(p.str),
    str: p.str,

    /// Pretty-print a syntax tree.
    pub fn print(self: @This(), w: p.Writer, lvl: u64) p.Writer.Error!void {
        try indent(w, lvl);
        try switch (self) {
            .int => |v| printInt(w, 0, v),
            .op_a => |v| printBinary(w, lvl, printExpr, v, "-a"),
            .op_b => |v| printUnary(w, lvl, printFile, v, "-b"),
            .op_bang => |v| printUnary(w, lvl, printExpr, v, "!"),
            .op_bang_equal => |v| printBinary(w, lvl, printStr, v, "!="),
            .op_c => |v| printUnary(w, lvl, printFile, v, "-c"),
            .op_d => |v| printUnary(w, lvl, printFile, v, "-d"),
            .op_e => |v| printUnary(w, lvl, printFile, v, "-e"),
            .op_ef => |v| printBinary(w, lvl, printFile, v, "-ef"),
            .op_eq => |v| printBinary(w, lvl, printInt, v, "-eq"),
            .op_equal => |v| printBinary(w, lvl, printStr, v, "="),
            .op_f => |v| printUnary(w, lvl, printFile, v, "-f"),
            .op_g => |v| printUnary(w, lvl, printFile, v, "-g"),
            .op_G => |v| printUnary(w, lvl, printFile, v, "-G"),
            .op_ge => |v| printBinary(w, lvl, printInt, v, "-ge"),
            .op_gt => |v| printBinary(w, lvl, printInt, v, "-gt"),
            .op_h => |v| printUnary(w, lvl, printFile, v, "-h"),
            .op_k => |v| printUnary(w, lvl, printFile, v, "-k"),
            .op_L => |v| printUnary(w, lvl, printFile, v, "-L"),
            .op_le => |v| printBinary(w, lvl, printInt, v, "-le"),
            .op_lt => |v| printBinary(w, lvl, printInt, v, "-lt"),
            .op_n => |v| printUnary(w, lvl, printFile, v, "-n"),
            .op_N => |v| printUnary(w, lvl, printStr, v, "-N"),
            .op_ne => |v| printBinary(w, lvl, printInt, v, "-ne"),
            .op_nt => |v| printBinary(w, lvl, printFile, v, "-nt"),
            .op_o => |v| printBinary(w, lvl, printExpr, v, "-o"),
            .op_O => |v| printUnary(w, lvl, printFile, v, "-O"),
            .op_ot => |v| printBinary(w, lvl, printFile, v, "-ot"),
            .op_p => |v| printUnary(w, lvl, printFile, v, "-p"),
            .op_r => |v| printUnary(w, lvl, printFile, v, "-r"),
            .op_s => |v| printUnary(w, lvl, printFile, v, "-s"),
            .op_S => |v| printUnary(w, lvl, printFile, v, "-S"),
            .op_t => |v| printUnary(w, lvl, printFd, v, "-t"),
            .op_u => |v| printUnary(w, lvl, printFile, v, "-u"),
            .op_w => |v| printUnary(w, lvl, printFile, v, "-w"),
            .op_x => |v| printUnary(w, lvl, printFile, v, "-x"),
            .op_z => |v| printUnary(w, lvl, printStr, v, "-z"),
            .str => |v| printStr(w, 0, v),
        };
    }

    /// Indent with spaces.
    fn indent(w: p.Writer, lvl: u64) p.Writer.Error!void {
        for (0..lvl * 2) |_| {
            try w.writeByte(' ');
        }
    }

    /// Pretty-print a binary operation.
    fn printBinary(
        w: p.Writer,
        lvl: u64,
        printer: anytype,
        v: Binary(printerValueType(printer)),
        repr: p.str,
    ) !void {
        try printOperator(w, repr);
        try printer(w, lvl + 1, v.left);
        try printer(w, lvl + 1, v.right);
    }

    /// Pretty-print an unary operation.
    fn printUnary(
        w: p.Writer,
        lvl: u64,
        printer: anytype,
        v: Unary(printerValueType(printer)),
        repr: p.str,
    ) !void {
        try printOperator(w, repr);
        try printer(w, lvl + 1, v);
    }

    /// Pretty-print the operator of an operation.
    fn printOperator(w: p.Writer, operator: p.str) p.Writer.Error!void {
        try w.print("{s}\n", .{operator});
    }

    /// Pretty-print an integer.
    fn printInt(w: p.Writer, lvl: u64, v: p.Int) p.Writer.Error!void {
        try indent(w, lvl);
        try w.print("int: {d}\n", .{v});
    }

    /// Pretty-print a file descriptor.
    fn printFd(w: p.Writer, lvl: u64, v: p.Fd) p.Writer.Error!void {
        try indent(w, lvl);
        try w.print("fd: {d}\n", .{v});
    }

    /// Pretty-print a file.
    fn printFile(w: p.Writer, lvl: u64, v: p.str) p.Writer.Error!void {
        try indent(w, lvl);
        try w.print("file: '{s}'\n", .{v});
    }

    /// Pretty-print a string.
    fn printStr(w: p.Writer, lvl: u64, v: p.str) p.Writer.Error!void {
        try indent(w, lvl);
        try w.print("str: '{s}'\n", .{v});
    }

    /// Pretty-print an expression.
    fn printExpr(w: p.Writer, lvl: u64, v: p.Expr) p.Writer.Error!void {
        try v.*.print(w, lvl);
    }

    fn printerValueType(printer: anytype) type {
        return @typeInfo(@TypeOf(printer)).Fn.params[2].type.?;
    }
};

pub fn ParseResult(comptime T: type) type {
    return struct {
        length: usize,
        value: T,
    };
}

pub fn Unary(comptime T: type) type {
    return T;
}

pub fn Binary(comptime T: type) type {
    return struct {
        left: T,
        right: T,
    };
}
