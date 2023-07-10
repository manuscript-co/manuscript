mkdir build && cd build


CXXFLAGS="-pthread -D_USE_PTHREAD_JIT_PERMISSIONS_API=1" cmake -DPORT="JSCOnly" -G "Ninja" \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DENABLE_STATIC_JSC=ON \
  -DCMAKE_BUILD_TYPE=RelWithDebugInfo \
  -DDEVELOPER_MODE=ON \
  -DENABLE_FTL_JIT=ON ../deps/Webkit

ninja -j8 jsc