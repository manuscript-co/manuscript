const std = @import("std");
const Builder = @import("std").build.Builder;
const join = std.fs.path.join;

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const staging = b.getInstallPath(.prefix, "staging");
    const mrt = b.addExecutable(.{ 
        .name = "mrt", 
        .root_source_file = std.build.FileSource.relative("src/mrt.zig"), 
        .target = target, 
        .optimize = optimize 
    });

    mrt.addIncludePath(try rp(b, &.{staging, "cpython", "include", "python3.12d" }));
    mrt.addIncludePath(try rp(b, &.{ "src", "101" }));

    // python
    mrt.addAssemblyFile(try rp(b, &.{ staging, "cpython", "lib", "libpython3.12d.a" }));
    // javascript
    mrt.addAssemblyFile(try rp(b, &.{ staging, "101", "lib101.a" }));
    mrt.addAssemblyFile(try rp(b, &.{ staging, "v8", "obj", "libv8_monolith.a" }));
    mrt.linkLibCpp();

    const prep = b.option(bool, "prep-staging", "builds v8, cpython, 101");
    if (safeUnwrap(prep)) {
        const stage = try prepStaging(b, target, optimize);
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

fn prepStaging(
    b: *Builder, 
    target: std.zig.CrossTarget, 
    optimize: std.builtin.Mode
) !*std.build.Step {
    const stage = b.step("staging-step", "builds all of staging");
    const py = try makePyStage(b, target, optimize);
    stage.dependOn(py);

    const v8 = try makeV8Stage(b, target, optimize);
    stage.dependOn(v8);

    const o1 = try make101Stage(b, target, optimize);
    stage.dependOn(o1);

    return stage;
}

// assemble release tarball
fn prepRelease(b: *Builder) !*std.build.Step {
    const rel = b.step("release-tarball", "");
    const f = b.addSystemCommand(&.{ "echo", "'mrt'" });
    rel.dependOn(&f.step);
    return rel;
}

fn rp(b: *Builder, parts: []const []const u8) ![]const u8 {
    const joined = try join(b.allocator, parts);
    if (std.fs.path.isAbsolute(joined)) return joined;
    return std.build.FileSource.relative(joined).path;
}

fn collapse(b: *Builder, s: []const u8) ![]const u8 {
    const out = try b.allocator.alloc(u8, s.len);
    _ = std.mem.replace(u8, s, "\n", " ", out);
    return out;
}

fn escapeDouble(b: *Builder, s: []const u8) ![]const u8 {
    const out = try b.allocator.alloc(u8, std.mem.replacementSize(u8, s, "\"", "\\\""));
    _ = std.mem.replace(u8, s, "\"", "\\\"", out);
    return out;
}

fn makePyStage(
    b: *Builder, 
    _: std.zig.CrossTarget, 
    optimize: std.builtin.Mode
) !*std.build.Step {
    const stagingDir = b.getInstallPath(.prefix, "staging");
    const py = b.step("python", "build-py");
    const pyout = try rp(b, &.{ stagingDir, "cpython" });
    const pysrc = try rp(b, &.{ "deps", "cpython" });
    const cf = b.addSystemCommand(&.{ 
        "./configure", 
        if(optimize == .Debug) "--with-pydebug" else "", 
        "--disable-test-modules", 
        b.fmt("--prefix={s}", .{pyout}), 
        "-q" 
    });
    cf.cwd = pysrc;
    const mk = b.addSystemCommand(&.{ "make", "-s", "-j4", "install" });
    mk.cwd = pysrc;
    mk.step.dependOn(&cf.step);
    py.dependOn(&mk.step);
    return py;
}

fn makeV8Stage(
    b: *Builder, 
    target: std.zig.CrossTarget, 
    optimize: std.builtin.Mode
) !*std.build.Step {
    const stagingDir = b.getInstallPath(.prefix, "staging");
    const v8 = b.step("v8", "build-v8");
    const v8src = try rp(b, &.{"deps", "v8"});
    const v8out = try rp(b, &.{stagingDir, "v8"});
    var gnargs = std.ArrayList([]const u8).init(b.allocator);
    defer gnargs.deinit();
    const basegn = 
    \\is_component_build=false
    \\v8_monolithic=true
    \\v8_use_external_startup_data=false
    \\v8_generate_external_defines_header=true
    \\v8_enable_31bit_smis_on_64bit_arch=true

    \\use_goma=false
    \\v8_enable_fast_mksnapshot=true
    \\v8_enable_snapshot_compression=true
    \\v8_enable_webassembly=false
    \\v8_enable_i18n_support=false

    \\use_custom_libcxx=false
    \\clang_use_chrome_plugins=false
    ;
    try gnargs.append(basegn);

    switch (target.getOsTag()) {
        .linux => {
            const linux = 
            \\v8_enable_private_mapping_fork_optimization=true
            ;
            try gnargs.append(linux);
        },
        .macos => {
            const mac = 
            \\clang_base_path="/usr"
            \\treat_warnings_as_errors=false
            \\use_lld=false
            \\use_gold=false
            \\target_os="mac"
            \\host_os="mac"
            ;
            try gnargs.append(mac);
        },
        else => unreachable
    }

    switch (target.getCpuArch()) {
        .arm, .aarch64 => {
            const arch = try collapse(b, 
            \\target_cpu="arm64"
            \\host_cpu="arm64"
        );
            try gnargs.append(arch);
        },
        .x86_64 => {
            try gnargs.append(try collapse(b, 
            \\target_cpu="x64"
            \\host_cpu="x64"
        ));},
        else => unreachable
    }

    if (optimize == .Debug) {
        const debug = 
        \\is_debug=true
        \\symbol_level=1
        \\v8_optimized_debug=true
        ;
        try gnargs.append(debug);
    }

    const gngen = b.addSystemCommand(&.{
        "gn", "gen", 
        v8out,
        b.fmt("--args={s}", .{ try collapse(b, 
            try std.mem.join(b.allocator, " ", gnargs.items))}),
    });
    gngen.cwd = v8src;

    const ninja = b.addSystemCommand(&.{
        "ninja", "-j4", "v8_monolith"
    });
    ninja.cwd = v8out; 
    ninja.step.dependOn(&gngen.step);
    v8.dependOn(&ninja.step);
    return v8;
}

fn make101Stage(
    b: *Builder, 
    _: std.zig.CrossTarget, 
    _: std.builtin.Mode
) !*std.build.Step {
    const stagingDir = b.getInstallPath(.prefix, "staging");
    const o1 = b.step("101", "builds 101");
    const o1out = try rp(b, &.{stagingDir, "101"});
    const root = std.Build.FileSource.relative(".").getPath(b);
    std.fs.cwd().access(o1out, .{ .mode = .read_only }) catch try std.fs.makeDirAbsolute(o1out);
    
    // TODO support windows
    const cmake = b.addSystemCommand(&.{
        "cmake", root, "-G", "Ninja",
        b.fmt("-DCMAKE_CXX_FLAGS={s}", .{
            try std.mem.join(b.allocator, " ", &.{
                b.fmt("-I{s}", .{try rp(b, &.{stagingDir, "v8", "gen", "include"})}),
                try rp(b, &.{stagingDir, "v8", "obj", "libv8_monolith.a"})
            })
        })
    });
    cmake.cwd = o1out;
    o1.dependOn(&cmake.step);
    return o1;
}
