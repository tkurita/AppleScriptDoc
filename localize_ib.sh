#!/bin/bash

# usage : localize_ib.sh ../English.lproj/MainMenu.nib
#    or
# usege : localize_ib.sh English.lproj/MainMenu.nib Japanese.lproj/MainMenu.nib
#
# Generate a localized nib|xib file from a strings file and an English ib file.
# It is assumed that the strings file is located in the current directory.
# The localized ib file is also generated in the current directory.

base_nib=$1
target_nib=$2
if [ -z ${target_nib} ]; then # second argument is omitted.
    target_nib=`basename ${base_nib}`
fi
target_path_nosuffix=`echo -n ${target_nib} | sed -E -e 's/\.(nib|xib)$//'`
strings_file=${target_path_nosuffix}.strings

if ! [ -e ${strings_file} ]; then
    ibtool --generate-strings-file ${strings_file} ${target_nib}
    echo " ${strings_file} is generated from ${target_nib}."
    exit
else
    echo "${strings_file} exist"
fi

ibtool --strings-file ${strings_file} --write ${target_nib} ${base_nib}
if [ $? ];then
    echo "Success to generate ${target_nib}."
fi

if [ -e ${target_nib}/.svn ]; then 
    rm -rf ${target_nib}/.svn
fi

