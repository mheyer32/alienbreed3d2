#!/bin/sh
find ./ab3d2_source/ -name \*.s -exec ./format_source.py {} \;
find ./ab3d2_source/ -name \*.i -exec ./format_source.py {} \;
