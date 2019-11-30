#!/usr/bin/env bash
set -e

TMP=~/code/tmp/mmix
SRC=~/code/llvm/llvm-project

PATCHES=$TMP/patches
BUILD=$TMP/build
REPO=$TMP/llvm-project

MMIX_SUPPORT_SUBMODULE=$REPO/mmix-llvm-support

OBJ_TESTS=$REPO/llvm/test/Object/MMIX
MC_TESTS=$REPO/llvm/test/MC/MMIX
LLC_TESTS=$REPO/lld/test/ELF/mmix-*
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

    cd $TMP
    git clone $SRC
    cd $REPO
    git remote set-url origin https://github.com/llvm/llvm-project.git
    git fetch

    echo ""
    echo "*******************"
    echo configuring repo and patches

    git format-patch origin/master..HEAD -k -o $PATCHES
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
        git submodule update --init
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

    echo
    if [ -d ${MC_TESTS} ]; then
        $BUILD/bin/llvm-lit -v $MC_TESTS
    fi

    echo
    if [ -d ${CODEGEN_TESTS} ]; then
        $BUILD/bin/llvm-lit -v $CODEGEN_TESTS
    fi

    echo
    if ls $LLC_TESTS 1> /dev/null 2>&1; then
        $BUILD/bin/llvm-lit -v $LLC_TESTS
    fi

    echo
    if [ -d ${MMIX_SUPPORT_SUBMODULE} ]; then
        cd $MMIX_SUPPORT_SUBMODULE
        make
    fi
done

cd build
ninja check-all
