# cd staging
# git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git
# cd depot_tools
# ./gclient sync

cd deps
mkdir -p v8/third_party/googletest/src

git clone --depth 1 https://chromium.googlesource.com/chromium/src/build.git v8/build
git clone --depth 1 https://chromium.googlesource.com/chromium/src/third_party/abseil-cpp.git \
    v8/third_party/abseil-cpp
git clone --depth 1 https://chromium.googlesource.com/chromium/src/tools/clang.git v8/tools/clang
git clone --depth 1 https://chromium.googlesource.com/external/github.com/google/googletest.git \
    v8/third_party/googletest/src
git clone --depth 1 https://chromium.googlesource.com/chromium/src/base/trace_event/common.git \
    v8/base/trace_event/common
git clone --depth 1 https://chromium.googlesource.com/chromium/src/third_party/zlib.git \
    v8/third_party/zlib

touch v8/build/config/gclient_args.gni
