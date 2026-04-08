const std = @import("std");
const ServerContext = @import("../Types.zig").ServerContext;

pub const ServerHandler = *const fn(ctx: *ServerContext) anyerror!void;
