const std = @import("std");
const deps = @import("deps.zig");
const p = deps.p;
const j = deps.j;
const VERSION = "0.0.1";

pub fn main() !void {
    if (parseArgs()) |file| {
        return runFile(file);
    }
    const stdout = std.io.getStdOut().writer();
    const help =
        \\manuscript version {s}
        \\jsc version {s}
        \\cpython version {s}
    ;
    const pv = p.Py_GetVersion();
    try stdout.print(help, .{ VERSION, "2.1", pv });
}

fn runFile(file: [:0]const u8) !void {
    if (std.mem.endsWith(u8, file, "py")) {
        try runCPython(file);
    } else if (std.mem.endsWith(u8, file, "js")) {
        try runJSC(file);
    }
}

fn runCPython(file: [:0]const u8) !void {
    const fd = p._Py_fopen_obj(file, "r+");
    defer _ = p.fclose(fd);
    var config: p.PyConfig = undefined;

    p.PyConfig_InitPythonConfig(&config);
    errdefer p.PyConfig_Clear(&config);

    try cpex(p.PyConfig_SetBytesString, .{ &config, &config.program_name, file });
    try cpex(p.Py_InitializeFromConfig, .{&config});

    p.PyConfig_Clear(&config);

    try cnz(p.PyRun_SimpleFile, .{ fd, file });
    if (p.Py_FinalizeEx() < 0) return mrterror.PythonException;
}

inline fn cpex(f: anytype, args: anytype) mrterror!void {
    const r = @call(std.builtin.CallModifier.auto, f, args);
    if (p.PyStatus_Exception(r) != 0) return mrterror.PythonException;
}

inline fn cnz(f: anytype, args: anytype) mrterror!void {
    const r = @call(std.builtin.CallModifier.auto, f, args);
    if (r != 0) return mrterror.NonZeroReturnCode;
}

// cli args
//    mrt program.[js, py]
fn parseArgs() ?[:0]const u8 {
    const allocator = std.heap.page_allocator;
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next().?; // cmd, binary name
    const file = args.next() orelse return null;
    return file;
}

fn runJSC(_: [:0]const u8) !void {
    j.jsc_init();
}

const mrterror = error{ NonZeroReturnCode, PythonException };