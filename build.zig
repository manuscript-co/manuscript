const std = @import("std");
const Builder = @import("std").build.Builder;
const fr = Builder.FileSource.relative;

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const e = b.addExecutable(.{ .name = "mrt", .root_source_file = fr("src/mrt.zig"), .target = target, .optimize = optimize });

    // python
    e.addIncludePath("staging/cpython/include/python3.13d");
    e.addAssemblyFile("staging/cpython/lib/libpython3.13d.a");

    // for cImport of jsc
    e.addIncludePath("staging/jsc");
    e.addIncludePath("staging/jsc/JavaScriptCore/Headers");

    e.addCSourceFile("src/rtj/road-to-jsc.h", &[_][]const u8{});

    e.linkLibCpp();
    e.addIncludePath("src/rtj");

    e.addAssemblyFile("staging/rtj/librtj.a");
    e.addAssemblyFile("staging/jsc/lib/libbmalloc.a");
    e.addAssemblyFile("staging/jsc/lib/libJavaScriptCore.a");
    e.addAssemblyFile("staging/jsc/lib/libWTF.a");

    e.linkSystemLibraryName("icucore");

    b.installArtifact(e);
}
