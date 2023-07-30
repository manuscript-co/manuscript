ONE_OUT=$PWD/staging/101
mkdir -p $ONE_OUT
cd $ONE_OUT  
cmake "../../" -G "Ninja"
ninja -j8