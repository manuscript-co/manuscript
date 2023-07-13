# rm -rf staging/jsc
mkdir -p staging/jsc
cd staging/jsc

CXXFLAGS="-pthread" cmake -DPORT="JSCOnly" -G "Ninja" \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DENABLE_STATIC_JSC=ON \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DDEVELOPER_MODE=ON \
  -DENABLE_FTL_JIT=ON ../../deps/Webkit

ninja -j8 jsc