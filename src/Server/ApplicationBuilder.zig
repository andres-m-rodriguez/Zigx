const std = @import("std");
const Router = @import("Internal/Router.zig");
const ServerHandler = @import("Internal/Types.zig").ServerHandler;
const App = @import("./Internal/App.zig");
const Self = @This();

pub fn init() Self {
    return .{};
}

pub fn deinit(self: *Self) void {
    _ = self;
}

pub fn build(self: *Self) App {
    _ = self;
    return App.init();
}
