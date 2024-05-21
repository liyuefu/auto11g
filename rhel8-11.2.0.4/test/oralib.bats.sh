#!/usr/bin/env bats
#setup first
setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  load "$DIR/../src/lib/bsfl.sh"
  load "$DIR/../src/lib/ext_bsfl.sh"
  load "$DIR/../src/lib/oralib.sh"
}

@test "check_root_fail" {
  run check_root "nome"
  assert_failure
}

@test "check_root_ok" {
  run check_root "root"
  assert_success
}
# @test "check_path_ends_with_slash_ok" {
#   run check_path_ends_with_slash '../src/para.cfg'
#   assert_output ""
# }
#
# #  "oracle_base_pr=/u01/app/oracle/" should be returned.
# @test "check_path_ends_with_slash_fail" {
#   run check_path_ends_with_slash '../src/para2.cfg'
# #  refute_output ""
#   assert_output -p "oracle_base_pr=/u01/app/oracle/"
# }
# @test "test_get_one_row_data_ok" {
#   run get_one_row_data  "../tmp/dbname.tmp" "../tmp/dbname.txt"
#   assert_output  "ctp"
#   # [ "$output" == "ctp" ]
#   # [ `cat tmp/dbname.txt`  == "ctp" ]
# }
#
#
# @test "test_get_multiple_row_data_ok" {
#   run get_multiple_row_data "../tmp/dbpath.tmp" "../tmp/dbpath.txt"
#   assert_output -p "/u02/oradata/ctp"
#   [ -f ../tmp/dbpath.txt ]
# }
# @test "test_get_diskgroup_name_ok" {
#   run get_diskgroup_name "../tmp/dbpath-asm.tmp" "../tmp/dg.txt"
#   assert_output "+DATA"
# }

## teardown cleanup 
teardown() {
  echo ""
#  rm -f ../tmp/*.txt
#  echo "teardown"
}

