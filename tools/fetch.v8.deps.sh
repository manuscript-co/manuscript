mkdir -p v8/third_party/googletest/src

# src url revision
fetch_specific() {
  rm -rf $1
  git clone $2 $1
  cd $1
  git reset --hard $3
  cd -
}


fetch_specific v8/base/trace_event/common https://chromium.googlesource.com/chromium/src/base/trace_event/common.git 147f65333c38ddd1ebf554e89965c243c8ce50b3

fetch_specific v8/build https://chromium.googlesource.com/chromium/src/build.git 1ee3f31d11821d3f8109171e660173c41da41f6e

fetch_specific v8/third_party/abseil-cpp https://chromium.googlesource.com/chromium/src/third_party/abseil-cpp.git 583dc6d1b3a0dd44579718699e37cad2f0c41a26

fetch_specific v8/tools/clang https://chromium.googlesource.com/chromium/src/tools/clang.git 02d5529a3fa5eb658949c576d5cc1f8348a9b515

fetch_specific v8/third_party/googletest/src https://chromium.googlesource.com/external/github.com/google/googletest.git af29db7ec28d6df1c7f0f745186884091e602e07

fetch_specific v8/third_party/zlib https://chromium.googlesource.com/chromium/src/third_party/zlib.git 526382e41c9c5275dc329db4328b54e4f344a204

touch v8/build/config/gclient_args.gni

ls v8