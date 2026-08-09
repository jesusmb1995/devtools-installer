#!/bin/bash

# check if bear is available
function __run_with_bear {
	if command -v bear >/dev/null 2>&1; then
		bear --append -- "$@"
	else
		"$@"
	fi
}

function cmake-build {
	__run_with_bear cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -S . -B build ${@:2} && __run_with_bear cmake --build build -j8
}

function bare-make-build {
	__run_with_bear bare-make generate --define CMAKE_EXPORT_COMPILE_COMMANDS=ON --define CMAKE_BUILD_TYPE=Release "${@}" && __run_with_bear bare-make build
}

function bare-make-build-debug {
	__run_with_bear bare-make generate -D CMAKE_EXPORT_COMPILE_COMMANDS=ON -D CMAKE_BUILD_TYPE=Debug ${@:1} && __run_with_bear bare-make build
}

function cmake-build-debug {
	__run_with_bear cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Debug -S . -B build "$@" && __run_with_bear cmake --build build -j 8
}

function _cmake-safe-rebuild {
  local build_fn="$1"; shift
  if [[ -d build ]]; then
    if [[ -f build/CMakeCache.txt || -d build/CMakeFiles ]]; then
      rm -rf build
    else
      echo "error: 'build/' exists but doesn't look like a CMake build directory" >&2
      return 1
    fi
  fi
  "$build_fn" "$@"
}

function cmake-rebuild {
  _cmake-safe-rebuild cmake-build "$@"
}

function cmake-rebuild-debug {
  _cmake-safe-rebuild cmake-build-debug "$@"
}

function bare-make-rebuild {
  _cmake-safe-rebuild bare-make-build "$@"
}

function bare-make-rebuild-debug {
  _cmake-safe-rebuild bare-make-build-debug "$@"
}

function cmake-vcpkg-build-debug { 
	bear --append -- cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=/opt/vcpkg/scripts/buildsystems/vcpkg.cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Debug ${@:2} && bear --append -- cmake --build build -j 8 
}

function cmake-run {
bear --append -- cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -S . -B build ${@:2} && bear --append -- cmake --build build --target "$1" -j8 --verbose && "./build/$1"
}

function cmake-help {
bear --append -- cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -S . -B build ${@:2} && cmake --build build --target help
}
