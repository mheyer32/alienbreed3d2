#!/bin/bash
a=$($1 -v 2>&1 | grep LTO)
b=(${a//=/ })
c=(${b[1]//libexec/ })
echo ${c[0]}
