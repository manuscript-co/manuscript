
PY_SRC=$PWD/deps/cpython
PY_OUT=$PWD/staging/cpython
mkdir -p $PY_OUT

cd $PY_SRC
./configure $DEBUG \
  --prefix="$PY_OUT" \
  --disable-test-modules \
  -q 

make -s -j8 install
