#!/bin/bash

# Create the build directory
mkdir -p ./build/lua

# Enable recursive matching
shopt -s globstar

for i in "./lua"/**; do
  if [ -f "$i" ]; then
    outdir=${i#./lua/}
    outdir=${outdir%/*.*}

    # Create the subdirectory in the build lua directory for the current lua subdirectory
    mkdir -p "./build/lua/$outdir"

    outfile="./build/lua/$outdir/"$(basename $i .lua 2>&1)"_.lua"

    cmd /c "LuaSrcDiet --none --opt-comments --opt-emptylines $i -o $outfile"
  fi
done

# Copy the other resources to the build directory

if [ -e ./materials/ ]; then
  cp -R ./materials/. ./build/materials
fi

if [ -e ./models/ ]; then
  cp -R ./models/. ./build/models
fi

if [ -e ./sound/ ]; then
  cp -R ./sound/. ./build/sound
fi

# Compress the build directory

cd ./build && tar -zcvf ../star-wars-vehicles-redux.tgz . && cd -

# Cleanup the build directory

rm -rf ./build
