#!/bin/bash

# Fail on first error
set -e

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
mkdir -p "$gnimag"/YesNoMathGames
cp -R Modules/Games/YesNoMathGames/Resources/ "$gnimag"/YesNoMathGames

mkdir -p "$gnimag"/FlowFree
cp Modules/Games/FlowFree/Scripts/pyflowsolver.py "$gnimag"/FlowFree
