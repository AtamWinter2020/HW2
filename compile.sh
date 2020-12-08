#!/bin/bash

echo
echo '[*] Compiling'
echo
make clean && make

echo
echo '[*] Copying "de.ko", "calculator" into VM'
echo
sudo mkdir _fs
sudo mount filesystem.img _fs
sudo cp -f de.ko calc _fs/root/
sudo umount _fs
sudo rm -rf _fs

echo
echo '[*] Done'
echo
