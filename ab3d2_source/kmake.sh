# This script is for building the binaries in the karlos-tkg mod. Probably needs removing from this repo.

rm ../../../miscdrive/karlos-tkg/Game/bin/*
make clean && make rel040

cp tkg_040 ../../../miscdrive/karlos-tkg/Game/bin/tkg_asm
cp tkgc_040 ../../../miscdrive/karlos-tkg/Game/bin/tkg_c

make clean && make dev040

cp tkg_dev_040 ../../../miscdrive/karlos-tkg/Game/bin/tkg_asm_dev
cp tkgc_dev_040 ../../../miscdrive/karlos-tkg/Game/bin/tkg_c_dev

