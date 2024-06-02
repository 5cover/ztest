const std = @import("std");
const parser = @import("parser.zig");

pub const Writer = std.fs.File.Writer;
pub const Allocator = std.mem.Allocator;

pub const str = []const u8;
pub const Expr = *const parser.Expression;
pub const Int = union(enum) {
    lit: i64,
    op_l: Unary(str),
};
pub const Fd = u32;
pub const File = str;

pub fn Unary(comptime T: type) type {
    return struct {
        operand: T,
    };
}

pub fn Binary(comptime T: type) type {
    return struct {
        left: T,
        right: T,
    };
}
