const std = @import("std");
const Builder = @import("std").build.Builder;
const join = std.fs.path.join;

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const mrt = b.addExecutable(.{ .name = "mrt", .root_source_file = try relativePath(b, &.{ "src", "mrt.zig" }), .target = target, .optimize = optimize });

    // python
    b.installArtifact(mrt);
}

fn relativePath(b: *Builder, parts: []const []const u8) !std.build.FileSource {
    const joined = try join(b.allocator, parts);
    return std.build.FileSource.relative(joined);
}
