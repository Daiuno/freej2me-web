#!/bin/bash
#
# build_ios.sh - Build script for freej2me-web iOS bundle
# Creates a minimized bundle with only essential files for iOS deployment
#
# Usage:
#   ./build_ios.sh        - Normal build
#

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/web"
OUTPUT_DIR="$SCRIPT_DIR/freej2me"

echo "=== freej2me-web iOS Build Script ==="
echo "Source: $SOURCE_DIR"
echo "Output: $OUTPUT_DIR"

# Clean and create output directory
echo ""
echo "=== Creating output directory ==="
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Copy main JAR file
echo ""
echo "=== Copying main JAR file ==="
cp "$SOURCE_DIR/freej2me-web.jar" "$OUTPUT_DIR/"
echo "  - freej2me-web.jar"

# Copy libjs/ directory (JavaScript bridge files)
echo ""
echo "=== Copying libjs/ directory ==="
mkdir -p "$OUTPUT_DIR/libjs"
for file in libcanvasfont.js libcanvasgraphics.js libgles2.js libjsreference.js libmediabridge.js libmidibridge.js; do
    if [ -f "$SOURCE_DIR/libjs/$file" ]; then
        cp "$SOURCE_DIR/libjs/$file" "$OUTPUT_DIR/libjs/"
        echo "  - $file"
    else
        echo "  - WARNING: $file not found"
    fi
done

# Install terser for minification
echo ""
echo "=== Installing terser for JS minification ==="
npm install --save-dev terser 2>/dev/null || true
export PATH="$PWD/node_modules/.bin:$PATH"

# Minify JS files in libjs/
echo ""
echo "=== Minifying JS files ==="
for f in "$OUTPUT_DIR/libjs"/*.js; do
    if [ -f "$f" ]; then
        npx terser "$f" -o "$f" --compress --mangle 2>/dev/null || true
        echo "  - Minified: $(basename $f)"
    fi
done

# Copy libmidi/ directory (MIDI synthesis)
echo ""
echo "=== Copying libmidi/ directory ==="
mkdir -p "$OUTPUT_DIR/libmidi"
# Copy essential files only (no test directory)
for file in libmidi.js libmidi.wasm worklet.js; do
    if [ -f "$SOURCE_DIR/libmidi/$file" ]; then
        cp "$SOURCE_DIR/libmidi/$file" "$OUTPUT_DIR/libmidi/"
        echo "  - $file"
    else
        echo "  - WARNING: $file not found"
    fi
done

# Minify JS files in libmidi/
for f in "$OUTPUT_DIR/libmidi"/*.js; do
    if [ -f "$f" ]; then
        npx terser "$f" -o "$f" --compress --mangle 2>/dev/null || true
        echo "  - Minified: $(basename $f)"
    fi
done

# Copy libmedia/ directory (media handling)
echo ""
echo "=== Copying libmedia/ directory ==="
mkdir -p "$OUTPUT_DIR/libmedia"
# Copy essential files (libmedia.js + transcode subdirectory)
if [ -f "$SOURCE_DIR/libmedia/libmedia.js" ]; then
    cp "$SOURCE_DIR/libmedia/libmedia.js" "$OUTPUT_DIR/libmedia/"
    echo "  - libmedia.js"
fi

# Copy transcode subdirectory (WASM for media transcoding)
mkdir -p "$OUTPUT_DIR/libmedia/transcode"
if [ -f "$SOURCE_DIR/libmedia/transcode/transcode.wasm" ]; then
    cp "$SOURCE_DIR/libmedia/transcode/transcode.wasm" "$OUTPUT_DIR/libmedia/transcode/"
    echo "  - transcode/transcode.wasm"
fi
if [ -f "$SOURCE_DIR/libmedia/transcode/transcode.js" ]; then
    cp "$SOURCE_DIR/libmedia/transcode/transcode.js" "$OUTPUT_DIR/libmedia/transcode/"
    echo "  - transcode/transcode.js"
fi
if [ -f "$SOURCE_DIR/libmedia/transcode/worker.js" ]; then
    cp "$SOURCE_DIR/libmedia/transcode/worker.js" "$OUTPUT_DIR/libmedia/transcode/"
    echo "  - transcode/worker.js"
fi

# Minify JS files in libmedia/
for f in "$OUTPUT_DIR/libmedia"/*.js; do
    if [ -f "$f" ]; then
        npx terser "$f" -o "$f" --compress --mangle 2>/dev/null || true
        echo "  - Minified: $(basename $f)"
    fi
done

# Minify JS files in libmedia/transcode/
for f in "$OUTPUT_DIR/libmedia/transcode"/*.js; do
    if [ -f "$f" ]; then
        npx terser "$f" -o "$f" --compress --mangle 2>/dev/null || true
        echo "  - Minified: transcode/$(basename $f)"
    fi
done

# Copy src/ directory (required for key handling modules)
echo ""
echo "=== Copying src/ directory (required for iOS) ==="
mkdir -p "$OUTPUT_DIR/src"
for file in eventqueue.js key.js; do
    if [ -f "$SOURCE_DIR/src/$file" ]; then
        cp "$SOURCE_DIR/src/$file" "$OUTPUT_DIR/src/"
        echo "  - $file"
    else
        echo "  - WARNING: $file not found"
    fi
done

# Minify JS files in src/
for f in "$OUTPUT_DIR/src"/*.js; do
    if [ -f "$f" ]; then
        npx terser "$f" -o "$f" --compress --mangle 2>/dev/null || true
        echo "  - Minified: $(basename $f)"
    fi
done

# Copy iOS.html
echo ""
echo "=== Copying iOS.html file ==="
cp "$SOURCE_DIR/ios.html" "$OUTPUT_DIR/index.html"
echo "  - iOS.html copied"

# Summary
echo ""
echo "=== Build Complete ==="
echo "Output directory: $OUTPUT_DIR"
echo ""
echo "Files copied:"
find "$OUTPUT_DIR" -type f -name "*" | sort | while read f; do
    size=$(ls -lh "$f" | awk '{print $5}')
    echo "  - ${f#$OUTPUT_DIR/} ($size)"
done

echo ""
echo "Bundle ready for iOS deployment!"
