#!/usr/bin/env bash
set -e

TMP=~/code/tmp/mmix
PATCHES=$TMP/patches
BUILD=$TMP/build
REPO=$TMP/llvm-project
SRC=~/code/llvm/llvm-project
BRANCH=inc-apply-test

OBJ_TESTS=$REPO/llvm/test/Object/MMIX
MC_TESTS=$REPO/llvm/test/MC/MMIX
CODEGEN_TESTS=$REPO/llvm/test/CodeGen/MMIX
CURRENT_PATCH=0

if [ $# -eq 1 ]; then
    CURRENT_PATCH=$1
else
    echo ""
    echo "*******************"
    echo preparing test environment

    rm -rf $TMP
    mkdir -p $PATCHES
    mkdir -p $BUILD

    #rsync -a $SRC/ $REPO --exclude build
    cd $TMP
    git clone $SRC
    cd $REPO
    git remote set-url origin https://github.com/llvm/llvm-project.git
    git fetch


    echo ""
    echo "*******************"
    echo configuring repo and patches

    git format-patch origin/master..HEAD -k -o $PATCHES
    # git checkout -b $BRANCH
    git reset --hard origin/master
fi

i=0
for patch in $PATCHES/*; do
    let ++i
    if (( i < $CURRENT_PATCH )); then
        continue
    fi
    if (( i > $CURRENT_PATCH )); then
        echo ""
        echo "*******************"
        echo "applying: $patch"
        cd $REPO
        git am --reject --whitespace=fix -k $patch
    fi

    echo ""
    echo "*******************"
    echo "building:"
    echo configuring build
    cd $BUILD
    if (( i < 3 )); then
        mmix-build $REPO/llvm "X86" ""
    else
        mmix-build $REPO/llvm "X86" "MMIX"
    fi
    ninja

    echo ""
    echo "*******************"
    echo "testing:"
    if [ -d ${OBJ_TESTS} ]; then
        $BUILD/bin/llvm-lit -v $OBJ_TESTS
    fi

    if [ -d ${MC_TESTS} ]; then
        $BUILD/bin/llvm-lit -v $MC_TESTS
    fi

    if [ -d ${CODEGEN_TESTS} ]; then
        $BUILD/bin/llvm-lit -v $CODEGEN_TESTS
    fi
done
