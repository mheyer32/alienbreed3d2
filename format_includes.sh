#!/bin/sh
# remove absolute paths and convert path to lower case
find ./ -name \*.s | xargs sed -i -r 's|(include[[:space:]]*\")(.*:)(.*)|\1\L\3|gi'
find ./ -name \*.s | xargs sed -i -r 's|(incbin[[:space:]]*\")(.*:)(.*)|\1\L\3|gi'
