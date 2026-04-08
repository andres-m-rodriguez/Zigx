const std = @import("std");
pub const ServerContext = struct {
    arena: std.mem.Allocator,
    io: std.Io,
    request: *std.http.Server.Request,
    params: std.StringHashMapUnmanaged([]const u8),
};
