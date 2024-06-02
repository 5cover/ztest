const std = @import("std");
const parser = @import("parser.zig");
const evaluator = @import("evaluator.zig");

pub fn main() !u8 {
    const stdout = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len == 2) {
        if (std.mem.eql(u8, args[1], "--version")) {
            try stdout.writeAll("ztest 0.0.0\n");
            return 0;
        }
        if (std.mem.eql(u8, args[1], "--help")) {
            try stdout.writeAll(help);
            return 0;
        }
    }

    //try dumpArgs(stdout, args);

    const result: u2 = run: {
        const ast = parser.parse(allocator, args) catch |err| {
            std.log.err("{}\n", .{err});
            break :run 2;
        };

        try dumpAst(stdout, ast);

        break :run if (ast) |vast| @intFromBool(!(evaluator.evaluate(vast) catch |err| {
            std.log.err("{}\n", .{err});
            break :run 2;
        })) else 1;
    };

    try stdout.print("Result : {d}\n", .{result});

    return result;
}

fn dumpArgs(w: std.fs.File.Writer, args: []const []const u8) !void {
    for (1.., args) |i, arg| {
        try w.print("#{d} {s}\n", .{ i, arg });
    }
}

fn dumpAst(w: std.fs.File.Writer, ast: ?parser.Expression) !void {
    try w.writeAll("AST\n");
    try if (ast) |vast| vast.prettyPrint(w, 1) else w.writeAll("empty\n");
}

const help =
    \\Usage: ztest EXPRESSION
    \\or:  ztest OPTION
    \\or:  ztest
    \\
    \\Exit with the status determined by EXPRESSION.
    \\
    \\      --help        display this help and exit
    \\      --version     output version information and exit
    \\
    \\An omitted EXPRESSION defaults to false.  Otherwise,
    \\EXPRESSION is true or false and sets exit status.  It is one of:
    \\
    \\  ( EXPRESSION )               EXPRESSION is true
    \\  ! EXPRESSION                 EXPRESSION is false
    \\  EXPRESSION1 -a EXPRESSION2   both EXPRESSION1 and EXPRESSION2 are true
    \\  EXPRESSION1 -o EXPRESSION2   either EXPRESSION1 or EXPRESSION2 is true
    \\
    \\  -n STRING            the length of STRING is nonzero
    \\  STRING               equivalent to -n STRING
    \\  -z STRING            the length of STRING is zero
    \\  STRING1 = STRING2    the strings are equal
    \\  STRING1 != STRING2   the strings are not equal
    \\
    \\  INTEGER1 -eq INTEGER2   INTEGER1 is equal to INTEGER2
    \\  INTEGER1 -ge INTEGER2   INTEGER1 is greater than or equal to INTEGER2
    \\  INTEGER1 -gt INTEGER2   INTEGER1 is greater than INTEGER2
    \\  INTEGER1 -le INTEGER2   INTEGER1 is less than or equal to INTEGER2
    \\  INTEGER1 -lt INTEGER2   INTEGER1 is less than INTEGER2
    \\  INTEGER1 -ne INTEGER2   INTEGER1 is not equal to INTEGER2
    \\
    \\  FILE1 -ef FILE2   FILE1 and FILE2 have the same device and inode numbers
    \\  FILE1 -nt FILE2   FILE1 is newer (modification date) than FILE2
    \\  FILE1 -ot FILE2   FILE1 is older than FILE2
    \\
    \\ -b FILE     FILE exists and is block special
    \\ -c FILE     FILE exists and is character special
    \\ -d FILE     FILE exists and is a directory
    \\ -e FILE     FILE exists
    \\
    \\ -f FILE     FILE exists and is a regular file
    \\ -g FILE     FILE exists and is set-group-ID
    \\ -G FILE     FILE exists and is owned by the effective group ID
    \\ -h FILE     FILE exists and is a symbolic link (same as -L)
    \\ -k FILE     FILE exists and has its sticky bit set
    \\
    \\  -L FILE     FILE exists and is a symbolic link (same as -h)
    \\  -N FILE     FILE exists and has been modified since it was last read
    \\  -O FILE     FILE exists and is owned by the effective user ID
    \\  -p FILE     FILE exists and is a named pipe
    \\  -r FILE     FILE exists and the user has read access
    \\  -s FILE     FILE exists and has a size greater than zero
    \\
    \\  -S FILE     FILE exists and is a socket
    \\  -t FD       file descriptor FD is opened on a terminal
    \\  -u FILE     FILE exists and its set-user-ID bit is set
    \\  -w FILE     FILE exists and the user has write access
    \\  -x FILE     FILE exists and the user has execute (or search) access
    \\
    \\Except for -h and -L, all FILE-related tests dereference symbolic links.
    \\Beware that parentheses need to be escaped (e.g., by backslashes) for shells.
    \\INTEGER may also be -l STRING, which evaluates to the length of STRING.
    \\
;
