#!/usr/bin/env bash
set -euo pipefail

mode="${1:-all}"
project="BeanBook.xcodeproj"
scheme="BeanBook"
build_destination="${IOS_BUILD_DESTINATION:-generic/platform=iOS Simulator}"
test_destination="${IOS_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0}"

usage() {
  cat <<EOF
Usage: ./scripts/agent-verify.sh [preflight|build|test|functions|all]

Environment overrides:
  IOS_BUILD_DESTINATION   Destination for xcodebuild build.
  IOS_TEST_DESTINATION    Destination for xcodebuild test.
EOF
}

run_preflight() {
  ./scripts/agent-preflight.sh
}

run_build() {
  xcodebuild -project "$project" -scheme "$scheme" -destination "$build_destination" build
}

run_tests() {
  xcodebuild test -project "$project" -scheme "$scheme" -destination "$test_destination"
}

run_functions() {
  npm --prefix functions run build
}

case "$mode" in
  preflight)
    run_preflight
    ;;
  build)
    run_preflight
    run_build
    ;;
  test)
    run_preflight
    run_tests
    ;;
  functions)
    run_preflight
    run_functions
    ;;
  all)
    run_preflight
    run_build
    run_functions
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
