mkdir -p staging/cpython
cd deps/cpython

GDBM_CFLAGS="-I$(brew --prefix gdbm)/include" \
GDBM_LIBS="-L$(brew --prefix gdbm)/lib -lgdbm" \
./configure --with-pydebug --with-openssl="$(brew --prefix openssl@3.0)" --prefix=$(realpath ../../staging/cpython)
make -s -j8