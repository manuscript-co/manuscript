// bag of functions
const std = @import("std");
const fs = @import("std").fs;
pub fn dupePath(bytes: []const u8) []u8 {
    var cp = std.mem.Allocator.dupe(std.heap.page_allocator, u8, bytes);
    for (cp) |*byte| {
        switch (byte.*) {
            '/', '\\' => byte.* = fs.path.sep,
            else => {},
        }
    }
    return cp;
}