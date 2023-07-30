pub const p = @cImport({
    @cDefine("PY_SSIZE_T_CLEAN", {});
    @cInclude("Python.h");
});

pub const j = @cImport({
    @cInclude("v8/v8.h");
});
