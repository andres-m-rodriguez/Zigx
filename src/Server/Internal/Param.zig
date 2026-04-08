const std = @import("std");
const Self = @This();

name: [] const u8,
type:ParamType,


const ParamType = enum {
    string,   // default, anything
    int,      // i64
    uint,     // u64
    float,    // f64
    guid,     // xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    bool,     // true/false
    slug,     // lowercase-hyphenated-string
    alpha,    // only a-z A-Z
    alphanum, // only a-z A-Z 0-9
    date,     // YYYY-MM-DD
};

pub fn isParam(value: []const u8) bool {
    if (value.len == 0) return false;
    if (value[0] == ':') return value.len > 1;
    if (value[0] == '{') return value.len > 2 and value[value.len - 1] == '}';
    return false;
}
pub fn paramInfo(value: []const u8) ?Self {
    if (!isParam(value)) return null;
    return .{
        .name = paramName(value),
        .type = paramType(value),
    };
}

pub fn paramName(value: []const u8) []const u8 {
    if (value[0] == ':') return value[1..];
    if (value[0] == '{') {
        const inner = value[1 .. value.len - 1];
        const colon = std.mem.indexOf(u8, inner, ":") orelse return inner;
        return inner[0..colon];
    }
    unreachable;
}


pub fn paramType(value: []const u8) ParamType {
    if (value[0] == ':') return .string;
    const inner = value[1 .. value.len - 1];
    const colon = std.mem.indexOf(u8, inner, ":") orelse return .string;
    const type_str = inner[colon + 1 ..];
    if (std.mem.eql(u8, type_str, "int")) return .int;
    if (std.mem.eql(u8, type_str, "guid")) return .guid;
    return .string;
}

