const std = @import("std");
const deps = @import("deps.zig");
const VERSION = "0.0.1";
const g = deps.ggml;
const j = deps.qjs;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const help =
        \\mrt version {s}
        \\qjs {any}
        \\ggml {any}
    ;
    deps.ggml.ggml_time_init();
    const param: deps.ggml.ggml_init_params = .{
        .mem_size=8192,
        .mem_buffer=null,
        .no_alloc=false
    };
    const ctx = deps.ggml.ggml_init(param);
    const rt = deps.qjs.JS_NewRuntime();
    try stdout.print(help, .{ VERSION, rt, ctx });
}