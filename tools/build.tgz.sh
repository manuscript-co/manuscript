rm -rf zig-out/mrt
mkdir -p zig-out/mrt/bin
mkdir -p zig-out/mrt/lib
cp zig-out/bin/mrt zig-out/mrt/bin
cp -r zig-out/staging/cpython/lib/python3.12 zig-out/mrt/lib/python3.12
rm -rf zig-out/mrt/lib/python3.12/test
rm -rf zig-out/mrt/lib/python3.12/config-3.12-*
find zig-out/mrt -name '*.py[co]' -exec rm -f {} ';' || true
tar czf ./zig-out/mrt.tgz ./zig-out/mrt