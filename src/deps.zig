pub const ggml = @cImport({
    @cInclude("build/include/ggml/ggml-backend.h");
});

pub const qjs = @cImport({
    @cInclude("build/include/quickjs/quickjs-libc.h");
});
