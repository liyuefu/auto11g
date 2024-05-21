#!/usr/bin/env bats

setup(){
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load '../src/lib/ext_bsfl.sh'
  load '../src/lib/bsfl.sh'

  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  PATH="$DIR/../src:$PATH"

}

@test "test_directory_exist_fun_should_ok" {
  run directory_exists "/etc"
  assert_success

}

@test "test_directory_exist_fun_err" {
  run directory_exists "/aaa"
  assert_failure
}

@test "test_/tmp_exists_ok" {
  [  -d '/tmp' ]
}

@test "test_/tmpa_not_exists_ok" {
  [ ! -d '/tmpa' ]
}
