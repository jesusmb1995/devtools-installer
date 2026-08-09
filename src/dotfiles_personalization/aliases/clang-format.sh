#!/bin/bash

# requires:  brew install clang-format@20 && apt install clang-format-19
function clangfh-diff {
 git-clang-format-19 --diff HEAD^ --extensions h,hh,hpp,c,cc,cpp
}
function clangfh {
 git-clang-format-19 HEAD^ --extensions h,hh,hpp,c,cc,cpp
}
function clangf-diff {
 git-clang-format-19 --diff $1 --extensions h,hh,hpp,c,cc,cpp
}

function clangf {
 git-clang-format-19 $1 --extensions h,hh,hpp,c,cc,cpp
}

function clang-format-all-dry {
git ls-files | grep -E '\.(c|cpp|h|hpp|cc)$' | xargs clang-format --dry-run --Werror
}
