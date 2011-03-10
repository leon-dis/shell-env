#!/bin/sh

PREFIX=`pwd`
echo "PREFIX=$PREFIX"


#using own lua

wget "http://www.lua.org/ftp/lua-5.1.4.tar.gz"
wget "http://luaforge.net/frs/download.php/4631/luaposix-5.1.7.tar.bz2"

echo "Unpacking lua and luaposix"
tar xf "lua-5.1.4.tar.gz"
tar xf "luaposix-5.1.7.tar.bz2"

echo "Patching lua and copyng posix module"
(cd lua-5.1.4 && patch -p1 < ../lua.patch && cp ../luaposix-5.1.7/lposix.c ../luaposix-5.1.7/modemuncher.c src/)


#build lua
echo "Building lua-5.1.4"
(cd lua-5.1.4 && make linux && make INSTALL_TOP=$PREFIX install)

#echo "Install shell-env.lua"
#install -d $PREFIX/bin/
#install shell-env.lua $PREFIX/bin/

echo "Build and install shell-env.bin"
(PREFIX=$PREFIX make)
install -d $PREFIX/bin/
install ./shell-env.bin $PREFIX/bin/

