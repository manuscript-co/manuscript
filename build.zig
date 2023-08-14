const std = @import("std");
const Builder = @import("std").build.Builder;
const join = std.fs.path.join;

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const toolchain = b.option([]const u8, "v8-toolchain", "toolchain to build v8");
    const CC = b.option([]const u8, "CC", "cc for staging");
    const CXX = b.option([]const u8, "CXX", "cxx for staging");

    const options: StagePrepOptions = .{ 
        .target = target, 
        .optimize = optimize, 
        .toolchain = toolchain, 
        .CC = CC, .CXX = CXX 
    };

    const js = b.option(bool, "js", "build only v8");
    if (safeUnwrap(js)) {
        const v8 = try makeV8(b, options);
        b.getInstallStep().dependOn(v8);
    }

    const bpy = b.option(bool, "py", "build only python");
    if (safeUnwrap(bpy)) {
        const py = try makePy(b, options);
        b.getInstallStep().dependOn(py);
    } 
    
    const bmrt = b.option(bool, "mrt", "build only mrt");
    if (safeUnwrap(bmrt)) {
        const mrt = try makeMrt(b, options);
        b.installArtifact(mrt);
    }
}

const StagePrepOptions = struct {
    target: std.zig.CrossTarget,
    optimize: std.builtin.Mode,
    toolchain: ?[]const u8,
    CC: ?[]const u8,
    CXX: ?[]const u8,
};

fn makeMrt(b: *Builder, options: StagePrepOptions) !*std.build.Step.Compile {
    const staging = try join(b.allocator, &.{"zig-out", "staging"});
    const mrt = b.addExecutable(.{ 
        .name = "mrt", 
        .root_source_file = std.build.FileSource.relative(
            try join(b.allocator, &.{"src", "mrt.zig"})), 
        .target = options.target, 
        .optimize = options.optimize 
    });

    mrt.addIncludePath(try lp(b, &.{
        staging, "cpython", "include", 
        if (options.optimize == .Debug) "python3.12d" else "python3.12"
    }));
    mrt.addIncludePath(try lp(b, &.{ "deps", "v8", "101" }));

    // python
    try setupCpythonFlags(b, options, mrt);
    mrt.addAssemblyFile(try lp(b, &.{ 
        staging, "cpython", "lib",
        if (options.optimize == .Debug) "libpython3.12d.a" else "libpython3.12.a"
    }));

    if (options.target.getOsTag() == .macos) {
        mrt.linkSystemLibrary("z");
        mrt.linkFramework("Foundation");
        mrt.linkFramework("SystemConfiguration");
    }

    mrt.addAssemblyFile(try lp(b, &.{
        "deps", "cpython", "Modules", "_decimal", "libmpdec", "libmpdec.a"
    }));
    mrt.addAssemblyFile(try lp(b, &.{
        "deps", "cpython", "Modules", "_hacl", "libHacl_Hash_SHA2.a"
    }));

    // javascript
    mrt.addAssemblyFile(try lp(b, &.{ staging, "v8", "obj", "lib101.a" }));
    mrt.addAssemblyFile(try lp(b, &.{ staging, "v8", "obj", "libv8_monolith.a" }));
    mrt.linkLibCpp();
    return mrt;
}

fn setupCpythonFlags(
    b: *Builder, 
    _: StagePrepOptions,
    _: *std.Build.Step.Compile
) !void {
    const stagingDir = b.getInstallPath(.prefix, "staging");
    const pyout = try rp(b, &.{ stagingDir, "cpython" });
    const cf = try rp(b, &.{
        pyout, "bin", "python3.12-config"
    });
    var cp = std.ChildProcess.init(&.{
        cf,
        "--embed",
        "--ldflags"
    }, b.allocator);
    _ = try cp.spawnAndWait();
    if (cp.stdout) |out| {
        const f = try out.readToEndAlloc(b.allocator, 0);
        std.log.debug("got flags {s}", .{f});
    }
}

fn escapeDouble(b: *Builder, s: []const u8) ![]const u8 {
    const out = try b.allocator.alloc(u8, std.mem.replacementSize(u8, s, "\"", "\\\""));
    _ = std.mem.replace(u8, s, "\"", "\\\"", out);
    return out;
}

fn makePy(
    b: *Builder, 
    options: StagePrepOptions
) !*std.build.Step {
    const stagingDir = b.getInstallPath(.prefix, "staging");
    const pyout = try rp(b, &.{ stagingDir, "cpython" });
    const pysrc = try rp(b, &.{ "deps", "cpython" });
    std.log.debug("pyout {s}", .{pyout});
    const cf = b.addSystemCommand(&.{ 
        "./configure", 
        "--disable-test-modules", 
        "--disable-shared",
        "--with-static-libpython",
        b.fmt("--prefix={s}", .{pyout}), 
        "-q"
    });

    if (options.optimize == .Debug) cf.addArg("--with-pydebug"); 
    if (options.CC) |CC| cf.setEnvironmentVariable("CC", CC);
    if (options.CXX) |CXX| cf.setEnvironmentVariable("CXX", CXX);
    cf.cwd = pysrc;

    const mk = b.addSystemCommand(&.{ "make", "-j4", "-s" });
    mk.cwd = pysrc;
    mk.step.dependOn(&cf.step);
    
    const mkinstall = b.addSystemCommand(&.{ "make", "altinstall" });
    mkinstall.cwd = pysrc;
    mkinstall.step.dependOn(&mk.step);
    return &mkinstall.step;
}

fn makeV8(
    b: *Builder, 
    options: StagePrepOptions
) !*std.build.Step {
    const stagingDir = b.getInstallPath(.prefix, "staging");
    const v8src = try rp(b, &.{"deps", "v8"});
    const v8out = try rp(b, &.{stagingDir, "v8"});

    const gnbin = try rp(b, &.{"tools", "gn"});
    const gngen = b.addSystemCommand(&.{
        gnbin, "gen",
        v8out,
        b.fmt("--args={s}", .{ try getGnArgs(b, options) }),
    });
    gngen.cwd = v8src;

    const ninja = b.addSystemCommand(&.{
        "ninja", "-j4", "v8_monolith", "101",  "--quiet"
    });
    ninja.cwd = v8out;
    ninja.step.dependOn(&gngen.step);
    return &ninja.step;
}

fn getGnArgs(b: *Builder, options: StagePrepOptions) ![]const u8 {
    var gnargs = std.ArrayList([]const u8).init(b.allocator);
    defer gnargs.deinit();

    const basegn =
        \\is_component_build=false
        \\v8_monolithic=true
        \\v8_use_external_startup_data=false
        \\v8_generate_external_defines_header=true
        \\v8_enable_31bit_smis_on_64bit_arch=true

        \\use_goma=false
        \\v8_enable_fast_mksnapshot=false
        \\v8_enable_snapshot_compression=true
        \\v8_enable_webassembly=false
        \\v8_enable_i18n_support=false
    
        \\cppgc_enable_young_generation=false
        \\cppgc_enable_caged_heap=false
        \\v8_enable_shared_ro_heap=false
        \\v8_enable_pointer_compression=false
        \\v8_enable_verify_heap=false
        \\v8_enable_sandbox=false

        \\use_custom_libcxx=false
        \\clang_use_chrome_plugins=false
    ;
    try gnargs.append(basegn);

    switch (options.target.getOsTag()) {
        .linux => {
            const linux =
                \\v8_enable_private_mapping_fork_optimization=true
                \\clang_base_path="/usr"
                \\is_clang=false
                \\target_os="linux"
                \\host_os="linux"
                \\cc_wrapper="ccache"
            ;
            try gnargs.append(linux);
        },
        .macos => {
            const mac =
                \\treat_warnings_as_errors=false
                \\use_lld=false
                \\use_gold=false
                \\target_os="mac"
                \\host_os="mac"
                \\cc_wrapper="ccache"
            ;
            if (options.toolchain) |chain| {
                try gnargs.append(b.fmt("clang_base_path=\"{s}\"", .{chain}));
            } else {
                try gnargs.append(b.fmt("clang_base_path=\"/usr\"", .{}));
            }
            try gnargs.append(mac);
        },
        else => unreachable
    }

    switch (options.target.getCpuArch()) {
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

    if (options.optimize == .Debug) {
        const debug =
            \\is_debug=true
            \\symbol_level=1
            \\v8_optimized_debug=true
        ;
        try gnargs.append(debug);
    }
    return collapse(b, 
            try std.mem.join(b.allocator, " ", gnargs.items));
}

fn rp(b: *Builder, parts: []const []const u8) ![]const u8 {
    const joined = try join(b.allocator, parts);
    if (std.fs.path.isAbsolute(joined)) return joined;
    return std.build.FileSource.relative(joined).getPath(b.getInstallStep().owner);
}

fn lp(b: *Builder, parts: []const []const u8) !std.Build.LazyPath {
    const joined = try join(b.allocator, parts);
    return std.build.FileSource.relative(joined);
}

fn collapse(b: *Builder, s: []const u8) ![]const u8 {
    const out = try b.allocator.alloc(u8, s.len);
    _ = std.mem.replace(u8, s, "\n", " ", out);
    return out;
}

inline fn safeUnwrap(v: ?bool) bool {
    if (v) |vu| {
        if (vu) return true;
    }
    return false;
}