const std = @import("std");
const http = std.http;
const ServerHandler = @import("Types.zig").ServerHandler;
const Param = @import("Param.zig");
const Self = @This();

get_stores: std.StringHashMapUnmanaged(Part) = .empty,
post_stores: std.StringHashMapUnmanaged(Part) = .empty,
put_stores: std.StringHashMapUnmanaged(Part) = .empty,
delete_stores: std.StringHashMapUnmanaged(Part) = .empty,
pub fn init() Self {
    return .{};
}
pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
    inline for (.{
        &self.get_stores,
        &self.post_stores,
        &self.put_stores,
        &self.delete_stores,
    }) |store| {
        var it = store.valueIterator();
        while (it.next()) |part| {
            part.deinit(allocator);
        }
        store.deinit(allocator);
    }
}
pub fn getRoute(self: *Self, allocator: std.mem.Allocator, value: []const u8, method: http.Method) !?FetchedPart {
    const store = getStore(self, method);
    var segments = std.mem.splitScalar(u8, value, '/');
    _ = segments.next(); // Skips whitespace on the left
    var current_store = store;
    var current_part: ?Part = null;
    var all_params: std.StringHashMapUnmanaged([]const u8) = .empty;
    if (value.len == 1 and value[0] == '/') {
        return if (current_store.get(value)) |part| FetchedPart{
            .params = .empty,
            .handler = part.handler.?,
        } else null;
    }

    while (segments.next()) |segment| {
        if (segment.len == 0) continue;
        var next = current_store.get(segment);
        if (next == null) {
            const part = current_part orelse unreachable;
            var value_it = part.parts.valueIterator();
            while (value_it.next()) |val| {
                if (val.param == null) continue;
                try all_params.put(allocator, val.param.?.name, segment);
                next = val.*;
            }

            if(next == null) return null;
        }
        current_part = next;
        current_store = &current_part.?.parts;
    }

    if (current_part) |part| {
        if (part.handler) |h| {
            return FetchedPart{ .params = all_params, .handler = h };
        }
    }
    return null;
}

pub fn mapRoute(
    self: *Self,
    allocator: std.mem.Allocator,
    value: []const u8,
    method: http.Method,
    handler: ServerHandler,
) !void {
    const store = getStore(self, method);
    var segments = std.mem.splitScalar(u8, value, '/');
    _ = segments.next(); // Skips whitespace on the left
    var current_store = store;
    var current_part: ?*Part = null;
    if (value.len == 1 and value[0] == '/') {
        const result = try current_store.getOrPut(allocator, "/");
        if (!result.found_existing) {
            result.value_ptr.* = .{
                .handler = handler,
                .parts = .empty,
                .param = null,
            };
        }
        return;
    }

    while (segments.next()) |segment| {
        if (segment.len == 0) continue;
        const result = try current_store.getOrPut(allocator, segment);
        if (!result.found_existing) {
            const param = Param.paramInfo(segment);

            result.value_ptr.* = .{
                .handler = null,
                .parts = .empty,
                .param = param,
            };
        }
        current_part = result.value_ptr;
        current_store = &result.value_ptr.*.parts;
    }

    if (current_part) |part| {
        part.handler = handler;
    }
}

pub const Part = struct {
    handler: ?ServerHandler,
    parts: std.StringHashMapUnmanaged(Part),
    param: ?Param,

    pub fn deinit(self: *Part, allocator: std.mem.Allocator) void {
        var children_it = self.parts.valueIterator();
        while (children_it.next()) |part| {
            part.deinit(allocator);
        }
        self.parts.deinit(allocator);
    }
};
pub const FetchedPart = struct {
    params: std.StringHashMapUnmanaged([]const u8),
    handler: ServerHandler,
};
fn getStore(router: *Self, method: http.Method) *std.StringHashMapUnmanaged(Part) {
    return switch (method) {
        .GET => &router.get_stores,
        .POST => &router.post_stores,
        .PUT => &router.put_stores,
        .DELETE => &router.delete_stores,
        else => @panic("Not implemented"),
    };
}
