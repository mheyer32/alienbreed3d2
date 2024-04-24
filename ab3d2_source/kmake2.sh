# This script is for building the binaries in the karlos-tkg mod. Probably needs removing from this repo.

make clean && make rel
make clean && make test
make clean && make dev

make clean && make rel040
make clean && make test040
make clean && make dev040

make clean && make rel060
make clean && make test060
make clean && make dev060
