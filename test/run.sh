#!/bin/bash

readonly TEST_DIR="$(cd "$(dirname "$0")" && pwd)"

TEST_SEARCH_PATH="$1"
if [ -z "$TEST_SEARCH_PATH" ]; then
  TEST_SEARCH_PATH="$(find "$TEST_DIR" -maxdepth 1 -name 'test-*' -type d)"
fi


readonly GENERATED_TEST_PLAYBOOK="$TEST_DIR/.test-playbook.tmp.yml"
readonly SETUP_PLAYBOOK_RE="{{ setup_playbook }}"
readonly TEARDOWN_PLAYBOOK_RE="{{ teardown_playbook }}"
readonly TEST_PLAYBOOK_RE="{{ test_playbook }}"


_escape_for_sed() {
  echo "$1" | sed -e 's/[]\/$*.^|[]/\\&/g'
}

_generate_test_playbook() {
  local test_playbook="$1"
  local pb_dir="$(dirname "$test_playbook")"

  local setup_playbook="$pb_dir/setup.yml"
  if [ ! -f "$setup_playbook" ]; then
    setup_playbook="$TEST_DIR/setup.yml"
  fi

  local teardown_playbook="$pb_dir/teardown.yml"
  if [ ! -f "$teardown_playbook" ]; then
    teardown_playbook="$TEST_DIR/teardown.yml"
  fi

  sed \
    -e "s/${SETUP_PLAYBOOK_RE}/$(_escape_for_sed "$setup_playbook")/g" \
    -e "s/${TEST_PLAYBOOK_RE}/$(_escape_for_sed "$test_playbook")/g" \
    -e "s/${TEARDOWN_PLAYBOOK_RE}/$(_escape_for_sed "$teardown_playbook")/g" \
    "${TEST_DIR}/test-template.yml.tpl" \
    > "$GENERATED_TEST_PLAYBOOK"
}

main() {
  local result=0
  local test_playbook
  local testcount=$(find $TEST_SEARCH_PATH -name test-*.yml | wc -l)
  local testname

  if [ $testcount -gt 1 ]; then
    TIME=time
  fi

  for test_playbook in `find $TEST_SEARCH_PATH -name test-*.yml`; do
    testname="$(basename "$test_playbook")"
    printf "\n$(tput setab 5)TEST [${testname}] ========================================================$(tput sgr0)\n"

    _generate_test_playbook "$test_playbook"

    $TIME ansible-playbook -i "$TEST_DIR/inventory" "$GENERATED_TEST_PLAYBOOK"
    if [ $? -eq 0 ]; then
      test_summary="$(tput setaf 2)SUCCESS$(tput sgr0)\t${testname}"
    else
      test_summary="$(tput setaf 1)FAILURE$(tput sgr0)\t${testname}"
      result=1
    fi
    summary="${summary}\n${test_summary}"

    if [ $testcount -gt 1 ]; then
      printf "${test_summary}\n"
    fi
  done
  
  printf "\n==== TEST summary ====${summary}\n"
  
  return $result
}

time main

