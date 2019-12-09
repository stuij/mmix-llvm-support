#!/usr/bin/env bash
set -e

print_help () {
    echo "usage: `basename $0` [option..] <repo> <tmp>"
    echo
    echo "   -k          keep the current check repo; don't delete it"
    echo "   -s          rebase from stuij master"
    echo "   -u          rebase from upstream master"
    echo "   -d          delete tmp dir, so remove patch apply info"
    echo "   -f          force cmdline options if patch checking in progress"
    echo "   -i          patching process status info"
    echo "   -h          this help text"
    echo "   <repo>      git repo we want to test"
    echo "   <tmp>       tmp directory holding patches, build dir"
}

SRC=~/code/llvm/llvm-project
TMP=~/code/tmp/mmix
REPO=$TMP/llvm-project
WORK=$TMP/work
PATCHES_TODO=$WORK/patches/todo

CURRENT_PATCH=0
KEEP=0
STUIJ=0
UPSTREAM=0
FORCE=0

while getopts ":ksudfih" opt; do
    case ${opt} in
        k ) KEEP=1
            ;;
        s ) STUIJ=1
            ;;
        u ) UPSTREAM=1
            ;;
        d ) DELETE="-d"
            ;;
        f ) FORCE=1
            ;;
        i ) cd $REPO && git --no-pager branch -a && echo && \
                  git --no-pager status && echo && \
                  git --no-pager log --oneline -n 30
            echo
            ls -R $PATCHES_TODO
            exit 0
            ;;
        h ) print_help
            exit 0
            ;;
        : ) echo "Invalid option: $OPTARG requires an argument" 1>&2
            exit 1
            ;;
        \? ) echo unrecognized option
             exit 1
             ;;
    esac
done
shift $((OPTIND -1))

if [ -d $PATCHES_TODO ] &&
       [ "$(find "$PATCHES_TODO" -mindepth 1 -print -quit 2>/dev/null)" ] &&
       [ $FORCE -eq 0 ]; then
    echo "##########################################"
    echo "patch checking in progress!! continuing..."
    echo "##########################################"
    echo check-patches.sh $REPO $WORK
    check-patches.sh $REPO $WORK
    exit 0
fi

if [[ $KEEP -eq 0 ]]; then
    rm -rf $TMP
    mkdir -p $TMP
    cd $TMP
    git clone $SRC $REPO

    cd $REPO
    git remote add upstream https://github.com/llvm/llvm-project.git
    git fetch upstream
    git remote add stuij git@github.com:stuij/mmix-llvm-backend.git
    git fetch stuij
fi

cd $REPO
if [ $STUIJ -eq 1 ]; then
    LOCAL_BASE=$(git merge-base master upstream/master)
    BASE_COMMIT=$(git merge-base stuij/master upstream/master)
    git rebase --onto $BASE_COMMIT $LOCAL_BASE
    DELETE="-d"
elif [ $UPSTREAM -eq 1 ]; then
    BASE_COMMIT=$(git merge-base master upstream/master)
    git pull --rebase upstream/master
    DELETE="-d"
else
    BASE_COMMIT=$(git merge-base master upstream/master)
fi

echo check-patches.sh $DELETE -c $BASE_COMMIT $REPO $WORK
check-patches.sh $DELETE -c $BASE_COMMIT $REPO $WORK
