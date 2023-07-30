
PY_SRC=$PWD/deps/cpython
PY_OUT=$PWD/staging/cpython
mkdir -p $PY_OUT

cd $PY_SRC
GDBM_CFLAGS="-I$(brew --prefix gdbm)/include" \
GDBM_LIBS="-L$(brew --prefix gdbm)/lib -lgdbm" \
./configure --with-pydebug \
  --with-openssl="$(brew --prefix openssl@3.0)" \
  --prefix="$PY_OUT" \
  --disable-test-modules \
  -q 

make -s -j8 install
