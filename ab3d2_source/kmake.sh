# This script is for building the binaries in the karlos-tkg mod. Probably needs removing from this repo.

rm ../../../miscdrive/karlos-tkg/Game/bin/68030/*
rm ../../../miscdrive/karlos-tkg/Game/bin/68040/*
rm ../../../miscdrive/karlos-tkg/Game/bin/68060/*

make clean
make all

cp tkg_dev_030 ../../../miscdrive/karlos-tkg/Game/bin/68030/tkg_dev
cp tkg_release_030 ../../../miscdrive/karlos-tkg/Game/bin/68030/tkg

cp tkg_dev_040 ../../../miscdrive/karlos-tkg/Game/bin/68040/tkg_dev
cp tkg_release_040 ../../../miscdrive/karlos-tkg/Game/bin/68040/tkg

cp tkg_dev_060 ../../../miscdrive/karlos-tkg/Game/bin/68060/tkg_dev
cp tkg_release_060 ../../../miscdrive/karlos-tkg/Game/bin/68060/tkg

