const std = @import("std");
const zigx = @import("zigx");
const http = std.http;
const ServerContext = @import("Server/Types.zig").ServerContext;
const ApplicationBuilder = @import("./Server/ApplicationBuilder.zig");

pub fn main(init: std.process.Init) !void {
    var builder = ApplicationBuilder.init();
    defer builder.deinit();

    var app = builder.build();
    app.mapGet(init.gpa, "/", Home);
    app.mapGet(init.gpa, "/api", Api);
    app.mapGet(init.gpa, "/home/{id}", WithParam);
    app.mapGet(init.gpa, "/home/{id}/users/{tester}", WithParam2);

    try app.run(init.io, init.arena.allocator());
}

pub fn Home(ctx: *ServerContext) !void {
    try ctx.request.respond("{\"message\": \"Hello from Home\"}", .{
        .extra_headers = &.{
            .{ .name = "Content-Type", .value = "application/json" },
        },
    });
}

pub fn Api(ctx: *ServerContext) !void {
    try ctx.request.respond("{\"message\": \"Welcome to the API\"}", .{
        .extra_headers = &.{
            .{ .name = "Content-Type", .value = "application/json" },
        },
    });
}

pub fn WithParam(ctx: *ServerContext) !void {
    try ctx.request.respond("{\"message\": \"Welcome to the Params\"}", .{
        .extra_headers = &.{
            .{ .name = "Content-Type", .value = "application/json" },
        },
    });
}

pub fn WithParam2(ctx: *ServerContext) !void {
    var data: std.json.ArrayHashMap([]const u8) = .{};

    try data.map.put(ctx.arena, "message", "Welcome to the Params");

    var it = ctx.params.iterator();
    while (it.next()) |entry| {
        try data.map.put(ctx.arena, entry.key_ptr.*, entry.value_ptr.*);
    }

    const json = try std.json.Stringify.valueAlloc(ctx.arena, data, .{});

    try ctx.request.respond(json, .{
        .extra_headers = &.{
            .{ .name = "Content-Type", .value = "application/json" },
        },
    });
}
