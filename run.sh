#!/bin/bash

# Compile and run the integrated Mac Intelligence prototype
if ./compile.sh MacIntel; then
    ./MacIntel
else
    echo "❌ Compilation failed."
fi
