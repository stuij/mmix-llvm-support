#!/usr/bin/env bash
set -e

print_help () {
    echo "usage: `basename $0` [option..] <repo> <tmp>"
    echo
    echo "   -c <commit> start of MMIX patches - 1"
    echo "   -l <nr>     parallel link jobs when building LLVM"
    echo "   -d          delete contents of tmp dir"
    echo "   -h          this help text"
    echo "   <repo>      git repo we want to test"
    echo "   <tmp>       tmp directory holding patches, build dir"
}

COMMIT=upstream/master
PARALLEL_LINK_JOBS=4
DELETE=0

while getopts ":c:l:dh" opt; do
    case ${opt} in
        c ) COMMIT=$OPTARG
            ;;
        l ) PARALLEL_LINK_JOBS=$OPTARG
            ;;
        d ) DELETE=1
            ;;
        h ) print_help
            exit 0
            ;;
        : ) echo "Invalid option: $OPTARG requires an argument" 1>&2
            exit 1
            ;;
        \? ) print_help
             exit 1
             ;;
  esac
done
shift $((OPTIND -1))

if [ $# -ne 2 ]; then
    echo "missing <repo> and <tmp> arguments, or argument list malformed"
    echo
    print_help
fi

REPO="$(cd "$1" && pwd -P)"
TMP="$(mkdir -p "$2" && cd "$2" && pwd -P)"

PATCHES_TODO=$TMP/patches/todo
PATCHES_DONE=$TMP/patches/done
BUILD=$TMP/build
TARGET_BIN=$BUILD/bin

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export PATH=$SCRIPT_DIR:$PATH

MMIX_SUPPORT_SUBMODULE=$REPO/mmix-llvm-support

OBJ_TESTS=$REPO/llvm/test/Object/MMIX
MC_TESTS=$REPO/llvm/test/MC/MMIX
LLC_TESTS=$REPO/lld/test/ELF/mmix-*
CODEGEN_TESTS=$REPO/llvm/test/CodeGen/MMIX

CLEAN_RUN=0
# if we explicitly want to delete the tmp dir, it doesn't exist
# or it is empty (we applied all patches), start a new run
if [ $DELETE -eq 1 ] ||
       [ ! -d $PATCHES_TODO ] ||
       [ ! "$(find "$PATCHES_TODO" -mindepth 1 -print -quit 2>/dev/null)" ]; then 
    CLEAN_RUN=1
fi

build () {
    echo ""
    echo "*******************"
    echo "building:"
    echo configuring build
    cd $BUILD
    if (( i < 3 )); then
        mmix-build $REPO/llvm "X86" "" $PARALLEL_LINK_JOBS
    else
        mmix-build $REPO/llvm "X86" "MMIX" $PARALLEL_LINK_JOBS
    fi
    ninja
}

test_patches () {
    echo ""
    echo "*******************"
    echo "testing"
    echo
    echo "lit tests:"
    echo "----------"
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

    if [ -d ${MMIX_SUPPORT_SUBMODULE} ]; then
        echo
        echo "simulator end-to-end tests:"
        echo "---------------------------"
        export PATH=$TARGET_BIN:$PATH
        cd $MMIX_SUPPORT_SUBMODULE
        make
    fi
}

if [ $CLEAN_RUN -eq 1 ]; then
    echo ""
    echo "*******************"
    echo preparing test environment

    rm -rf $TMP
    mkdir -p $PATCHES_TODO
    mkdir -p $PATCHES_DONE
    mkdir -p $BUILD

    cd $REPO

    echo ""
    echo "*******************"
    echo configuring repo and patches

    git format-patch ^$COMMIT -k -o $PATCHES_TODO
    git reset --hard $COMMIT
fi

if [ $CLEAN_RUN -eq 0 ]; then
    build
    test_patches
fi

for patch in $PATCHES_TODO/*; do
    echo ""
    echo "*******************"
    echo "applying: $patch"
    cd $REPO
    git am --reject --whitespace=fix -k $patch
    mv $patch $PATCHES_DONE
    git submodule update --init
    sleep 2
    build
    test_patches
    echo
done

echo "patches applied and tested!"
echo

cd $BUILD
echo "*******************"
echo "check-all"
echo 
ninja check-all
