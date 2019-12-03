#!/usr/bin/env bash
set -e

print_help () {
    echo "usage: `basename $0` [option..]"
    echo
    echo "   -s <src>    src repo directory"
    echo "   -t <tmp>    tmp directory holding patches, build dir, cloned repo"
    echo "   -p <nr>     patch number to start off from when resuming
                         (TODO: we should automate this)"
    echo "   -l <nr>     parallel link jobs when building LLVM"
    echo "   -c          script called from within CI (don't re-clone repo)"
    echo "   -h          this help text"
}

SRC=~/code/llvm/llvm-project
TMP=~/code/tmp/mmix

CURRENT_PATCH=0
CI=0
PARALLEL_LINK_JOBS=4

while getopts ":s:t:p:l:ch" opt; do
    case ${opt} in
        p ) CURRENT_PATCH=$OPTARG
            ;;
        c ) CI=1
            ;;
        s ) SRC="$(cd "$OPTARG" && pwd -P)"
            ;;
        l ) PARALLEL_LINK_JOBS=$OPTARG
            ;;
        t ) TMP="$(mkdir -p "$OPTARG" && cd "$OPTARG" && pwd -P)"
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

PATCHES=$TMP/patches
BUILD=$TMP/build
TARGET_BIN=$BUILD/bin

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export PATH=$SCRIPT_DIR:$PATH

if [ $CI -eq 0 ]; then
    REPO=$TMP/llvm-project
else
    REPO=$SRC
fi

MMIX_SUPPORT_SUBMODULE=$REPO/mmix-llvm-support

OBJ_TESTS=$REPO/llvm/test/Object/MMIX
MC_TESTS=$REPO/llvm/test/MC/MMIX
LLC_TESTS=$REPO/lld/test/ELF/mmix-*
CODEGEN_TESTS=$REPO/llvm/test/CodeGen/MMIX

if [ $CURRENT_PATCH -eq 0 ]; then
    echo ""
    echo "*******************"
    echo preparing test environment

    rm -rf $TMP
    mkdir -p $PATCHES
    mkdir -p $BUILD

    if [ $CI -eq 0 ]; then
        cd $TMP
        git clone $SRC
    fi

    cd $REPO

    if [ $CI -eq 0 ]; then
        git remote add upstream https://github.com/llvm/llvm-project.git
        git fetch upstream
    fi

    echo ""
    echo "*******************"
    echo configuring repo and patches

    git format-patch upstream/master..HEAD -k -o $PATCHES
    git reset --hard upstream/master
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
        mmix-build $REPO/llvm "X86" "" $PARALLEL_LINK_JOBS
    else
        mmix-build $REPO/llvm "X86" "MMIX" $PARALLEL_LINK_JOBS
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
        export PATH=$TARGET_BIN:$PATH
        cd $MMIX_SUPPORT_SUBMODULE
        make
    fi
done

cd $BUILD
ninja check-all
