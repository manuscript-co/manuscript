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
        \\mrt version {s}
        \\v8 version {s}
        \\cpython version {s}
    ;
    const pv = p.Py_GetVersion();
    const jv = j.v8_version();
    try stdout.print(help, .{ VERSION, jv, pv });
}

fn runFile(file: [:0]const u8) !void {
    if (std.mem.endsWith(u8, file, "py")) {
        try runCPython(file);
    } else if (std.mem.endsWith(u8, file, "js")) {
        try runV8on101(file);
    }
}

fn runCPython(file: [:0]const u8) !void {
    const fd = p.fopen(file, "r+");
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

fn runV8on101(file: [:0]const u8) !void {
    const fd = try std.fs.cwd().openFile(file, .{ .mode = .read_only });
    defer fd.close();
    const stats = try std.fs.File.stat(fd);
    const buf = try std.heap.c_allocator.alloc(u8, stats.size);
    defer std.heap.c_allocator.free(buf);
    _ = try std.fs.File.readAll(fd, buf);
    j.exec_file(buf.ptr);
}

const mrterror = error{ NonZeroReturnCode, PythonException };

test "versions" {
    const pv = p.Py_GetVersion();
    std.debug.assert(std.mem.startsWith(u8, pv, "3.12"));
    const jv = j.v8_version();
    std.debug.assert(std.mem.eql(u8, jv, "11.7.99"));
}
