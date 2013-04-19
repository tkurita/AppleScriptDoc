#!/bin/bash

# generate a strings file from a ib file, if specified strings file does not exist.

strings_file=$1
path_nosuffix=`echo -n ${strings_file}|sed -E -e 's/\.strings$//'`

if [ -e ${strings_file} ]; then
    echo "${strings_file} exists. Nothing to do."
    exit 0
fi

ib_file=${path_nosuffix}.xib
if [ -e ${ib_file} ]; then
    ibtool --generate-strings-file ${strings_file} ${ib_file}
    touch ${ib_file}
    exit 0
fi

ib_file=${path_nosuffix}.nib
if [ -e ${ib_file} ]; then
    ibtool --generate-strings-file ${strings_file} ${ib_file}
    touch ${ib_file}
fi
