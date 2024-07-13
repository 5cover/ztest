const std = @import("std");
const parser = @import("parser.zig");
const p = @import("primitives.zig");

pub fn evaluate(expr: parser.Expression) bool {
    return switch (expr) {
        .int => true,
        .op_a => |v| evaluate(v.left.*) and evaluate(v.right.*),
        .op_b => |v| opb(v),
        .op_bang => |v| !evaluate(v.*),
        .op_bang_equal => |v| !p.streq(v.left, v.right),
        .op_c => |v| opc(v),
        .op_d => |v| opd(v),
        .op_e => |v| ope(v),
        .op_ef => |v| opef(v.left, v.right),
        .op_eq => |v| v.left == v.right,
        .op_equal => |v| p.streq(v.left, v.right),
        .op_f => |v| opf(v),
        .op_g => |v| opg(v),
        .op_G => |v| opG(v),
        .op_ge => |v| v.left >= v.right,
        .op_gt => |v| v.left > v.right,
        .op_h, .op_L => |v| oph(v),
        .op_k => |v| opk(v),
        .op_le => |v| v.left <= v.right,
        .op_lt => |v| v.left < v.right,
        .op_N => |v| opN(v),
        .op_n => |v| v.len > 0,
        .op_ne => |v| v.left != v.right,
        .op_nt => |v| opnt(v.left, v.right),
        .op_o => |v| evaluate(v.left.*) or evaluate(v.right.*),
        .op_O => |v| opO(v),
        .op_ot => |v| opot(v.left, v.right),
        .op_p => |v| opp(v),
        .op_r => |v| opr(v),
        .op_s => |v| ops(v),
        .op_S => |v| opS(v),
        .op_t => |v| opt(v),
        .op_u => |v| opu(v),
        .op_w => |v| opw(v),
        .op_x => |v| opx(v),
        .op_z => |v| v.len == 0,
        .str => |v| v.len > 0,
    };
}

const c = @cImport({
    //@cInclude("stdio.h");
    @cInclude("errno.h");
    @cInclude("sys/types.h");
    @cInclude("sys/stat.h");
    @cInclude("unistd.h");
});

fn statOf(f: p.str) !c.struct_stat {
    var stat_buf: c.struct_stat = undefined;
    if (c.stat(@ptrCast(f), &stat_buf) != 0) {
        return error.StatFailed;
    }
    return stat_buf;
}

fn opb(f: p.str) bool {
    const stat = statOf(f) catch return false;
    return c.S_ISBLK(stat.st_mode);
}

fn opc(f: p.str) bool {
    const stat = statOf(f) catch return false;
    return c.S_ISCHR(stat.st_mode);
}

fn opd(f: p.str) bool {
    const stat = statOf(f) catch return false;
    return c.S_ISDIR(stat.st_mode);
}

fn ope(f: p.str) bool {
    return c.access(@ptrCast(f), c.F_OK) == 0;
}

fn opef(lf: p.str, rf: p.str) bool {
    const stat_lf = statOf(lf) catch return false;
    const stat_rf = statOf(rf) catch return false;

    return stat_lf.st_dev == stat_lf.st_dev and stat_lf.st_ino == stat_rf.st_ino;
}

fn opf(f: p.str) bool {
    const stat = statOf(f) catch return false;
    return c.S_ISREG(stat.st_mode);
}

fn opg(f: p.str) bool {
    const stat = statOf(f) catch return false;
    return (stat.st_mode & c.S_ISGID) != 0;
}

fn opG(f: p.str) bool {
    const stat = statOf(f) catch return false;
    return stat.st_gid == c.getegid();
}

fn oph(f: p.str) bool {
    const stat = statOf(f) catch return false;
    return c.S_ISLNK(stat.st_mode);
}

fn opk(f: p.str) bool {
    const stat = statOf(f) catch return false;
    return (stat.st_mode & c.S_ISVTX) != 0;
}

fn opN(f: p.str) bool {
    const stat = statOf(f) catch return false;
    return stat.st_atim.tv_nsec < stat.st_mtim.tv_nsec;
}

fn opnt(lf: p.str, rf: p.str) bool {
    const stat_lf = statOf(lf) catch return false;
    const stat_rf = statOf(rf) catch return false;
    return stat_lf.st_mtim.tv_nsec > stat_rf.st_mtim.tv_nsec;
}

fn opO(f: p.str) bool {
    const stat = statOf(f) catch return false;
    return stat.st_uid == c.geteuid();
}

fn opot(lf: p.str, rf: p.str) bool {
    return !opnt(lf, rf);
}

fn opp(f: p.str) bool {
    const stat = statOf(f) catch return false;
    return c.S_ISFIFO(stat.st_mode);
}

fn opr(f: p.str) bool {
    return c.access(@ptrCast(f), c.R_OK) == 0;
}

fn ops(f: p.str) bool {
    const stat = statOf(f) catch return false;
    return stat.st_size > 0;
}

fn opS(f: p.str) bool {
    const stat = statOf(f) catch return false;
    return c.S_ISSOCK(stat.st_mode);
}

fn opt(fd: p.Fd) bool {
    return c.isatty(fd) != 0;
}

fn opu(f: p.str) bool {
    const stat = statOf(f) catch return false;
    return (stat.st_mode & c.S_ISUID) != 0;
}

fn opw(f: p.str) bool {
    return c.access(@ptrCast(f), c.W_OK) == 0;
}

fn opx(f: p.str) bool {
    return c.access(@ptrCast(f), c.X_OK) == 0;
}
