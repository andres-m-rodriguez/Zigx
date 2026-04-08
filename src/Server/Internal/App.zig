const std = @import("std");
const http = std.http;
const net = std.Io.net;
const HttpMethod = http.Method;
const Self = @This();
const Router = @import("Router.zig");
const ServerHandler = @import("Types.zig").ServerHandler;
const ServerContext = @import("../Types.zig").ServerContext;

router: Router,
pub fn init() Self {
    return .{
        .router = .init(),
    };
}
pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
    self.router.deinit(allocator);
}

pub fn mapGet(self: *Self, allocator: std.mem.Allocator, comptime value: []const u8, handler: ServerHandler) void {
    self.router.mapRoute(allocator, value, HttpMethod.GET, handler) catch @panic("Failed to map get method");
}

pub fn run(self: *Self, io: std.Io, allocator: std.mem.Allocator) !void {
    const addr = try net.IpAddress.parse("::1", 8080);

    var server = try addr.listen(io, .{ .reuse_address = true });
    defer server.deinit(io);
    const stream = try server.accept(io);
    defer stream.close(io);

    var read_buf: [8192]u8 = undefined;
    var write_buf: [8192]u8 = undefined;

    var stream_reader = stream.reader(io, &read_buf);
    var stream_writer = stream.writer(io, &write_buf);

    var http_server = http.Server.init(&stream_reader.interface, &stream_writer.interface);

    while (true) {
        var request = http_server.receiveHead() catch |err| switch (err) {
            error.HttpConnectionClosing => break,
            else => break,
        };

        var request_arena = std.heap.ArenaAllocator.init(allocator);
        defer request_arena.deinit();
        const request_allocator = request_arena.allocator();
        const fetched_route = try self.router.getRoute(request_allocator,request.head.target, request.head.method);
        var server_context = ServerContext{
            .io = io,
            .arena = request_allocator, 
            .request = &request,
            .params = .empty,

        };

        if (fetched_route) |route| {
            server_context.params = route.params;
            try route.handler(&server_context);
        } else {
            try request.respond("Not found", .{
                .status = http.Status.not_found,
            });
        }
        if (!request.head.keep_alive) break;
    }
}
