# This script is for building the binaries in the karlos-tkg mod. Probably needs removing from this repo.

rm ../../../miscdrive/karlos-tkg/Game/bin/*

make clean
make FLAVOR=release CPU=040 BUILD=c
make FLAVOR=dev CPU=040 BUILD=c

cp tkg_release_040 ../../../miscdrive/karlos-tkg/Game/bin/tkg
cp tkg_dev_040 ../../../miscdrive/karlos-tkg/Game/bin/tkg_dev

#make FLAVOR=release CPU=030 BUILD=c
#make FLAVOR=dev CPU=030 BUILD=c

#cp tkg_release_030 ../../../miscdrive/karlos-tkg/Game/bin/tkg
#cp tkg_dev_030 ../../../miscdrive/karlos-tkg/Game/bin/tkg_dev

