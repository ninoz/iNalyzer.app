#!/bin/sh

dir=$(pwd)

cd $(dirname $0)

if [ -f /Applications/Doxygen.app/Contents/Resources/doxygen ]; then
        /Applications/Doxygen.app/Contents/Resources/doxygen ./doxygen/dox.template
else
        doxygen ./doxygen/dox.template
fi

open ./index.html

cd "$dir"
