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
    // javascript
    mrt.addAssemblyFile(try rp(b, &.{ "staging", "101", "lib101.a" }));
    mrt.addAssemblyFile(try rp(b, &.{ "staging", "v8", "obj", "libv8_monolith.a" }));
    mrt.linkLibCpp();

    const prep = b.option(bool, "prep-staging", "builds v8, cpython, 101");
    if (safeUnwrap(prep)) {
        const stage = try prepStaging(b);
        mrt.step.dependOn(stage);
    }

    const relTgz = b.option(bool, "release-tarball", "builds release tarball");
    if (safeUnwrap(relTgz)) {
        const release = try prepRelease(b);
        b.getInstallStep().dependOn(release);
    }

    b.installArtifact(mrt);
}

inline fn safeUnwrap(v: ?bool) bool {
    if (v) |vu| {
        if (vu) return true;
    }
    return false;
}

fn prepStaging(b: *Builder) !*std.build.Step {
    // prep staging
    // what needs to happen
    // 1/ build cpython
    // 2/ build v8
    // 3/ build 101
    // assemble release tarball
    // additionally
    //  gn needs explicit telling for
    //  host os, host cpu, target os, target cpu
    //  debug flags translates down to python and v8 differently
    const stage = b.step("staging-step", "builds all of staging");
    const py = b.addSystemCommand(&.{ "bash", try rp(b, &.{ "tools", "mac.build.cpython.sh" }) });
    stage.dependOn(&py.step);

    const one = b.addSystemCommand(&.{ "bash", try rp(b, &.{ "tools", "mac.build.101.sh" }) });
    const v8 = b.addSystemCommand(&.{ "bash", try rp(b, &.{ "tools", "mac.build.v8.sh" }) });
    one.step.dependOn(&v8.step);
    stage.dependOn(&one.step);
    return stage;
}

fn prepRelease(b: *Builder) !*std.build.Step {
    const rel = b.step("release-tarball", "");
    const f = b.addSystemCommand(&.{ "echo", "'mrt'" });
    rel.dependOn(&f.step);
    return rel;
}

fn rp(b: *Builder, comptime parts: []const []const u8) ![]const u8 {
    const joined = try join(b.allocator, parts);
    return std.build.FileSource.relative(joined).path;
}
