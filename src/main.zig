const std = @import("std");
const p = @import("primitives.zig");
const parser = @import("parser.zig");
const evaluator = @import("evaluator.zig");

pub fn main() !u8 {
    const alloc = std.heap.page_allocator;
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    return run(std.io.getStdErr().writer().any(), args, alloc);
}

pub fn run(stderr: p.Writer, args: p.Args, allocator: p.Allocator) !u8 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    //try dumpArgs(stderr, args);

    const result: u2 = run: {
        var diag = parser.Diagnostic{};
        const ast_o = parser.Parser.init(arena.allocator(), &diag)
        // skip first argument (program location)
            .parse(args[1..]) catch |err| {
            try stderr.print("{s}: ", .{args[0]});
            try diag.report(stderr, err);
            break :run 2;
        };

        //try dumpAst(stderr, ast_o);

        break :run if (ast_o) |ast| @intFromBool(!evaluator.evaluate(ast.value)) else 1;
    };

    //try stderr.print("Result: {d}\n", .{result});

    return result;
}

fn dumpArgs(w: p.Writer, args: []const []const u8) !void {
    for (1.., args) |i, arg| {
        try w.print("#{d} {s}\n", .{ i, arg });
    }
}

fn dumpAst(w: p.Writer, ast: ?parser.ParseResult(parser.Expression)) !void {
    try w.writeAll("AST\n");
    try if (ast) |vast| vast.value.print(w, 1) else w.writeAll("empty\n");
}
