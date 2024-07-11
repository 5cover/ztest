const std = @import("std");
const parser = @import("parser.zig");

pub const str = []const u8;
pub const Expr = *const parser.Expression;
pub const Int = c_longlong;
pub const Fd = c_int;
