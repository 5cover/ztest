const std = @import("std");
const parser = @import("parser.zig");

pub const chr = u8;
pub const str = []const chr;
pub const Expr = *const parser.Expression;
pub const Int = i64;
pub const Fd = c_int;

pub const Args = []const str;
pub const Writer = std.io.AnyWriter;
pub const Allocator = std.mem.Allocator;

pub fn Comparer(comptime T: type) type {
    return fn (T, T) bool;
}

pub fn Predicate(comptime T: type) type {
    return fn (T) bool;
}

// Utilities

pub fn streq(a: str, b: str) bool {
    return std.mem.eql(chr, a, b);
}

/// Is an error (*needle*) is part of an error set type (*haystack*)?
pub fn errorSetContains(haystack: type, needle: anyerror) bool {
    for (@typeInfo(haystack).ErrorSet.?) |e| {
        if (streq(e.name, @errorName(needle))) {
            return true;
        }
    }
    return false;
}

/// Allocates an object and assigns its value, then returns it as a constant.
pub fn create(allocator: Allocator, value: anytype) !*const @TypeOf(value) {
    const ptr = try allocator.create(@TypeOf(value));
    errdefer allocator.destroy(ptr);
    ptr.* = value;
    return ptr;
}

/// Can a slice be indexed at *i*?
///
/// If `true` is returned, then any natural *n* &le; *i* indexes *slice*.
pub fn indexes(i: usize, slice: anytype) bool {
    return i < slice.len;
}

pub fn indexOf(comptime T: type, value: T, slice: []const T, compare: Comparer(T)) ?usize {
    return indexOfPos(T, value, slice, 0, compare);
}

pub fn indexOfPos(comptime T: type, value: T, slice: []const T, start_index: usize, compare: Comparer(T)) ?usize {
    for (slice[start_index..], start_index..) |e, i| {
        if (compare(value, e)) return i;
    } else return null;
}

pub fn indexOfFirst(comptime T: type, predicate: Predicate(T), slice: []const T) ?usize {
    return indexOfFirstPos(T, predicate, slice, 0);
}

pub fn indexOfFirstPos(comptime T: type, predicate: Predicate(T), slice: []const T, start_index: usize) ?usize {
    for (slice[start_index..], start_index..) |e, i| {
        if (predicate(e)) return i;
    } else return null;
}
