const std = @import("std");
const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const e = b.addExecutable(.{
        .name = "msr",
        .root_source_file = .{ .path = "src/msr.zig" },
        .target = target,
        .optimize = optimize,
    });
    e.addIncludePath("staging/cpython/include/python3.13d");
    e.addAssemblyFile("staging/cpython/lib/libpython3.13d.a");
    b.installArtifact(e);
}
