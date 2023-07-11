const std = @import("std");
const p = @import("python.zig").p;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello, {s}!\n", .{"world"});
    p.Py_Initialize();
    _ = p.PyRun_SimpleString("from time import time,ctime\nprint('Today is', ctime(time()))\n");
}
