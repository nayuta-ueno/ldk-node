#!/bin/bash
BINDINGS_DIR="bindings/golang/ldk_node"
TARGET_DIR="target/bindings/golang"
PROJECT_DIR="ldk-node-golang"

DYNAMIC_LIB_PATH="target/x86_64-unknown-linux-gnu/release/libldk_node.so"

mkdir -p $BINDINGS_DIR || exit 1
mkdir -p $TARGET_DIR || exit 1

# build libldk_node.so
rustup target add x86_64-unknown-linux-gnu || exit 1
cargo build --release --target x86_64-unknown-linux-gnu --features uniffi || exit 1
cp $DYNAMIC_LIB_PATH "$BINDINGS_DIR"/ || exit 1

# generate go file
uniffi-bindgen-go ./bindings/ldk_node.udl -o "$TARGET_DIR"/ || exit 1

mv "$TARGET_DIR"/uniffi/ldk_node/ldk_node.go "$TARGET_DIR"/uniffi/ldk_node/ldk_node.go.org
sed -e "s/LdkNode/LDKNode/g" "$TARGET_DIR"/uniffi/ldk_node/ldk_node.go.org | \
    sed -e '/import "C"/i // #cgo LDFLAGS: -L${SRCDIR} -lldk_node\n// #include "ldk_node.h"' > "$TARGET_DIR"/uniffi/ldk_node/ldk_node.go

cp "$TARGET_DIR"/uniffi/ldk_node/ldk_node.go "$BINDINGS_DIR"/ || exit 1

first=`grep -m1 -e "/\\*" -n $BINDINGS_DIR/ldk_node.go | cut -d : -f1`
last=`grep -m1 -e "\\*/" -n $BINDINGS_DIR/ldk_node.go | cut -d : -f1`
cat $BINDINGS_DIR/ldk_node.go | sed -n $((first+1)),$((last-1))p > $BINDINGS_DIR/ldk_node.h
