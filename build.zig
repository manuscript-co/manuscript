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
    e.addIncludePath("src/road-to-jsc");

    e.linkLibCpp();
    e.addIncludePath("staging/jsc");
    e.addIncludePath("staging/jsc/JavaScriptCore/Headers");
    e.addIncludePath("staging/jsc/JavaScriptCore/PrivateHeaders");
    e.addIncludePath("staging/jsc/WTF/Headers");
    e.addIncludePath("staging/jsc/bmalloc/Headers");

    e.addAssemblyFile("staging/jsc/lib/libbmalloc.a");
    e.addAssemblyFile("staging/jsc/lib/libJavaScriptCore.a");
    e.addAssemblyFile("staging/jsc/lib/libWTF.a");

    e.linkSystemLibraryName("icucore");

    b.installArtifact(e);
}
