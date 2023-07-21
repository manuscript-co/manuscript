rm -rf staging/rtj
mkdir -p staging/rtj
cd staging/rtj

cmake -G "Ninja" \
  -DJSC=$PWD/../jsc \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo  ../../src/rtj

ninja -j8