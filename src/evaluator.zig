const std = @import("std");
const parser = @import("parser.zig");
const p = @import("primitives.zig");

pub fn evaluate(expr: parser.Expression) !bool {
    return switch (expr.value) {
        .fd => error.UnexpectedFd,
        .file => error.UnexpectedFile,
        .int => error.UnexpectedInt,
        .op_a => |v| try evaluate(v.left.*) and try evaluate(v.right.*),
        .op_b => |v| opb(v.operand),
        .op_c => |v| opc(v.operand),
        .op_d => |v| opd(v.operand),
        .op_e => |v| ope(v.operand),
        .op_ef => |v| opef(v.left, v.right),
        .op_eq => |v| relval(v.left) == relval(v.right),
        .op_equal => |v| std.mem.eql(u8, v.left, v.right),
        .op_f => |v| opf(v.operand),
        .op_g => |v| opg(v.operand),
        .op_G => |v| opG(v.operand),
        .op_ge => |v| relval(v.left) >= relval(v.right),
        .op_gt => |v| relval(v.left) > relval(v.right),
        .op_h => |v| oph(v.operand),
        .op_k => |v| opk(v.operand),
        .op_L => |v| opL(v.operand),
        .op_le => |v| relval(v.left) <= relval(v.right),
        .op_lt => |v| relval(v.left) < relval(v.right),
        .op_n => |v| v.operand.len > 0,
        .op_N => |v| opN(v.operand),
        .op_ne => |v| relval(v.left) != relval(v.right),
        .op_not_equal => |v| !std.mem.eql(u8, v.left, v.right),
        .op_nt => |v| opnt(v.left, v.right),
        .op_O => |v| opO(v.operand),
        .op_o => |v| try evaluate(v.left.*) or try evaluate(v.right.*),
        .op_ot => |v| opot(v.left, v.right),
        .op_p => |v| opp(v.operand),
        .op_r => |v| opr(v.operand),
        .op_s => |v| ops(v.operand),
        .op_S => |v| opS(v.operand),
        .op_t => |v| opt(v.operand),
        .op_u => |v| opu(v.operand),
        .op_w => |v| opw(v.operand),
        .op_x => |v| opx(v.operand),
        .op_z => |v| v.operand.len == 0,
        .str => |v| v.len > 0,
    };
}

fn relval(i: p.Int) i64 {
    return switch (i) {
        .lit => |v| v,
        .op_l => |l| @intCast(l.operand.len),
    };
}

fn opa(f: p.File) !bool {
    _ = f;
    return error.NotImplemented;
}

fn opb(f: p.File) !bool {
    _ = f;
    return error.NotImplemented;
}

fn opc(f: p.File) !bool {
    _ = f;
    return error.NotImplemented;
}

fn opd(f: p.File) !bool {
    _ = f;
    return error.NotImplemented;
}

fn ope(f: p.File) !bool {
    _ = f;
    return error.NotImplemented;
}

fn opef(lf: p.File, rf: p.File) !bool {
    _ = lf;
    _ = rf;
    return error.NotImplemented;
}

fn opf(f: p.File) !bool {
    _ = f;
    return error.NotImplemented;
}

fn opg(f: p.File) !bool {
    _ = f;
    return error.NotImplemented;
}

fn opG(f: p.File) !bool {
    _ = f;
    return error.NotImplemented;
}

fn oph(f: p.File) !bool {
    _ = f;
    return error.NotImplemented;
}

fn opk(f: p.File) !bool {
    _ = f;
    return error.NotImplemented;
}

fn opL(f: p.File) !bool {
    _ = f;
    return error.NotImplemented;
}

fn opN(f: p.File) !bool {
    _ = f;
    return error.NotImplemented;
}

fn opnt(lf: p.File, rf: p.File) !bool {
    _ = lf;
    _ = rf;
    return error.NotImplemented;
}

fn opO(f: p.File) !bool {
    _ = f;
    return error.NotImplemented;
}

fn opo(le: p.Expr, re: p.Expr) !bool {
    _ = le;
    _ = re;
    return error.NotImplemented;
}

fn opot(lf: p.File, rf: p.File) !bool {
    _ = lf;
    _ = rf;
    return error.NotImplemented;
}

fn opp(f: p.File) !bool {
    _ = f;
    return error.NotImplemented;
}

fn opr(f: p.File) !bool {
    _ = f;
    return error.NotImplemented;
}

fn ops(f: p.File) !bool {
    _ = f;
    return error.NotImplemented;
}

fn opS(f: p.File) !bool {
    _ = f;
    return error.NotImplemented;
}

fn opt(fd: p.Fd) !bool {
    _ = fd;
    return error.NotImplemented;
}

fn opu(f: p.File) !bool {
    _ = f;
    return error.NotImplemented;
}

fn opw(f: p.File) !bool {
    _ = f;
    return error.NotImplemented;
}

fn opx(f: p.File) !bool {
    _ = f;
    return error.NotImplemented;
}
