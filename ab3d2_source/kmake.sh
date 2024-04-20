# This script is for building the binaries in the karlos-tkg mod. Probably needs removing from this repo.

rm ../../../miscdrive/karlos-tkg/Game/bin/*
make clean
make hires hiresC

# Make sure they are stripped
m68k-amigaos-strip hires
m68k-amigaos-strip hiresC

cp hires ../../../miscdrive/karlos-tkg/Game/bin/tkg_asm
cp hiresC ../../../miscdrive/karlos-tkg/Game/bin/tkg_c

make clean

make dev 
cp hires ../../../miscdrive/karlos-tkg/Game/bin/tkg_asm_dev
cp hiresC ../../../miscdrive/karlos-tkg/Game/bin/tkg_c_dev

