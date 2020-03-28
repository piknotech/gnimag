#!/bin/bash

# Copy required resources into the application support folder.
# Both xcode-built and make-built versions of gnimag can find them there.
gnimag="$HOME/Library/Application Support/gnimag"

# Clean-mode
if [ "$1" == "clean" ]
then
    rm -rf "$gnimag"
    exit 0
fi

# Copy resources
mkdir -p "$gnimag"/identiti
cp -R Sources/Games/identiti/Resources/OCR "$gnimag"/identiti
