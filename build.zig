const std = @import("std");
const Builder = @import("std").build.Builder;
const join = std.fs.path.join;

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const mrt = b.addExecutable(.{ .name = "mrt", .root_source_file = std.build.FileSource.relative("src/mrt.zig"), .target = target, .optimize = optimize });
    mrt.addIncludePath(try rp(b, &.{ "staging", "cpython", "include", "python3.12d" }));

    mrt.addIncludePath(try rp(b, &.{ "src", "101" }));

    // python
    mrt.addAssemblyFile(try rp(b, &.{ "staging", "cpython", "lib", "libpython3.12d.a" }));
    mrt.addAssemblyFile(try rp(b, &.{ "staging", "101", "lib101.a" }));
    mrt.addAssemblyFile(try rp(b, &.{ "staging", "v8", "obj", "libv8_monolith.a" }));

    mrt.linkLibCpp();
    b.installArtifact(mrt);
}

fn rp(b: *Builder, comptime parts: []const []const u8) ![]const u8 {
    const joined = try join(b.allocator, parts);
    return std.build.FileSource.relative(joined).path;
}
