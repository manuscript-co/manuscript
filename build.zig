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

    const bqjs = b.option(bool, "js", "build only qjs");
    if (safeUnwrap(bqjs)) {
        const qjs = try makeQjs(b, options);
        b.getInstallStep().dependOn(qjs);
    }

    const bggml = b.option(bool, "ggml", "build only ggml");
    if (safeUnwrap(bggml)) {
        const ggml = try makeggml(b, options);
        b.getInstallStep().dependOn(ggml);
    } 

    if (safeUnwrap(bggml) or safeUnwrap(bqjs)) return;
    
    const mrt = try makeMrt(b, options);
    b.getInstallStep().dependOn(&mrt.step);
    b.installArtifact(mrt);
    try setupIntTests(b, options, mrt);
    try setupTests(b, options);
}

fn makeggml(b: *Builder, _: StagePrepOptions) !*std.build.Step {
    const stagingDir = b.pathFromRoot("build");
    const mk = b.addSystemCommand(&.{ "cmake", 
        b.fmt("-DCMAKE_INSTALL_PREFIX={s}", .{stagingDir}),
        "-DGGML_BUILD_TESTS=OFF",
        "-DGGML_BUILD_EXAMPLES=OFF",
        "-DBUILD_SHARED_LIBS=OFF",
        "-B", "build"
    });
    mk.cwd = b.dupePath("deps/ggml");
    const mkinstall = b.addSystemCommand(&.{ "make", "install" });
    mkinstall.cwd = b.dupePath("deps/ggml/build");
    mkinstall.step.dependOn(&mk.step);
    return &mkinstall.step;
}

fn makeQjs(b: *Builder, _: StagePrepOptions) !*std.build.Step {
    const stagingDir = b.pathFromRoot("build");
    const mk = b.addSystemCommand(&.{ "make", "-j4", "-s" });
    mk.cwd = b.dupePath("deps/quickjs");
    const mkinstall = b.addSystemCommand(&.{ "make", "install" });
    mkinstall.setEnvironmentVariable("DESTDIR", stagingDir);
    mkinstall.setEnvironmentVariable("PREFIX", "");
    mkinstall.cwd = mk.cwd;
    mkinstall.step.dependOn(&mk.step);
    const mkclean = b.addSystemCommand(&.{ "make", "clean" });
    mkclean.cwd = mk.cwd;
    mkclean.step.dependOn(&mkinstall.step);
    return &mkclean.step;
}

fn setupIntTests(b: *Builder, _: StagePrepOptions, mrt: *std.build.Step.Compile) !void {
    const step = b.step("int-test", "");
    const tests = [_][]const u8{
        b.dupePath("tests/js/index.js"),
        b.dupePath("tests/py/index.py"),
        // TODO
        // b.dupePath("tests/ts/index.ts"),
        // b.dupePath("tests/cjs/index.cjs"),
        // b.dupePath("tests/mjs/index.mjs"),
    };
    
    for (tests) |t| {
        const rt = b.addRunArtifact(mrt);
        rt.addArg(t);
        step.dependOn(&rt.step);
    }
}

fn setupTests(b: *Builder, options: StagePrepOptions) !void {
    const t = b.step("test", "");
    const mt = b.addTest(.{
        .root_source_file = std.build.FileSource.relative(
            try join(b.allocator, &.{"src", "mrt.zig"})),
        .target = options.target, 
        .optimize = options.optimize 
    });
    try oldPrepCompileStep(b, options, mt);
    const run_unit_tests = b.addRunArtifact(mt);
    t.dependOn(&run_unit_tests.step);
}

const StagePrepOptions = struct {
    target: std.zig.CrossTarget,
    optimize: std.builtin.Mode,
    toolchain: ?[]const u8,
    CC: ?[]const u8,
    CXX: ?[]const u8,
};

fn makeMrt(b: *Builder, options: StagePrepOptions) !*std.build.Step.Compile {
    const mrt = b.addExecutable(.{ 
        .name = "mrt", 
        .root_source_file = std.build.FileSource.relative(
            try join(b.allocator, &.{"src", "mrt.zig"})), 
        .target = options.target, 
        .optimize = options.optimize 
    });    
    try prepCompileStep(b, options, mrt);
    return mrt;
}

fn prepCompileStep(
    b: *Builder, 
    opts: StagePrepOptions, 
    mrt: *std.build.Step.Compile
) !void {
    const ip = std.build.FileSource.relative(".");
    mrt.addIncludePath(ip);
    const libp = std.build.FileSource.relative(b.dupePath("build/lib"));
    mrt.addLibraryPath(libp);
    const qjspath = std.build.FileSource.relative(b.dupePath("build/lib/quickjs"));
    mrt.addLibraryPath(qjspath);
    mrt.linkLibC();
    mrt.linkSystemLibrary("ggml");
    mrt.linkSystemLibrary("quickjs");
    if (opts.target.getOsTag() == .macos) {
        mrt.linkFramework("Accelerate");
    }
}

inline fn safeUnwrap(v: ?bool) bool {
    if (v) |vu| {
        if (vu) return true;
    }
    return false;
}