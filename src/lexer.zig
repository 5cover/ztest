const std = @import("std");

pub fn lex(allocator: std.mem.Allocator, args: []const []const u8) ![]Token {
    var tokens = try std.ArrayListUnmanaged(Token).initCapacity(allocator, 255);

    for (1..args.len) |i| {
        const item: ?Token = switch (args[i][0]) {
            '(' => Token{ .index = i, .length = 1, .value = .r_paren },
            else => null,
        };

        if (item == null) {
            std.debug.print("error: argument '{s}' is unknown token\n", .{args[i]});
        } else {
            try tokens.append(allocator, item.?);
        }
    }

    return try tokens.toOwnedSlice(allocator);
}

pub const Token = struct {
    index: usize,
    length: usize,
    value: union(enum) {
        bang_equal,
        bang,
        eof,
        equal,
        fd: u64,
        file: []const u8,
        integer: u64,
        l_paren,
        opt_a,
        opt_b,
        opt_c,
        opt_d,
        opt_e,
        opt_ef,
        opt_eq,
        opt_f,
        opt_g,
        opt_G,
        opt_ge,
        opt_gt,
        opt_h,
        opt_k,
        opt_l,
        opt_L,
        opt_le,
        opt_lt,
        opt_n,
        opt_N,
        opt_ne,
        opt_nt,
        opt_o,
        opt_O,
        opt_ot,
        opt_p,
        opt_r,
        opt_s,
        opt_S,
        opt_t,
        opt_u,
        opt_w,
        opt_z,
        r_paren,
        string: []const u8,
    },
};
