V8_SRC=$PWD/deps/v8
V8_OUT=$PWD/staging/v8

mkdir -p $V8_OUT
cp tools/mac.arm64.args.gn $V8_OUT/args.gn

cd $V8_SRC; gn gen $V8_OUT
cd $V8_OUT; ninja -j4 v8_monolith d8
