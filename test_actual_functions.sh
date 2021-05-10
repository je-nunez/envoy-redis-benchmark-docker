#!/bin/bash
#
# Run Sysbench tests on an Envoy proxy with a Redis upstream database.

# This file needs to define at least two functions:
#
# wait_till_backend_db_is_up(): it waits till the backend (upstream) db is up
#
# run_all_combined_envoy_tests(): it runs all the tests on Envoy that are
#                                 recorded by perf-record.

# The functions log() and get_all_envoy_stats(), both receiving an optional
# parameter with a message to print in the log before the envoy stats, are
# available in the environment to be called by the functions in this file.

function wait_till_backend_db_is_up() {
  # The Envoy port ${ENVOY_PROXY_PORT} can be up but the backend db server
  # upstream doesn't need to be up yet.

  local tmp_file=/tmp/ping_reply_$$.txt

  while true; do
    # /usr/local/bin/memtier_benchmark ${MEMTIER_CONN_PING_TEST_ARGS}
    # Redis-cli exit(1) at read-errors (in cliReadReply(...), and at connect
    # errors (from cliConnect(...)):
    # https://github.com/redis/redis/blob/master/src/redis-cli.c
    set -x
    /usr/local/bin/redis-cli -h "${ENVOY_HOST}" -p "${ENVOY_PROXY_PORT}"  \
                             PING > "${tmp_file}"
    set +x

    if (( $? == 0 )); then
      /bin/grep -F PONG "${tmp_file}"
      if (( $? == 0 )); then break; fi
    fi

    log "Waiting 5 more seconds for ${DRIVER}"
    sleep 5
  done

  log "Upstream ${DRIVER} db is also ready. Tests can start"
}


function run_redis_benchmark_test() {

  if [[ ! -x /usr/local/bin/redis-benchmark ]]; then
    log "/usr/local/bin/redis-benchmark not found"
  elif [[ -z "${REDIS_BENCHMARK_TEST_ARGS}" ]]; then
    log "redis-benchmark not configured (var REDIS_BENCHMARK_TEST_ARGS empty)"
  else
    log "Starting redis-benchmark test"
    /usr/local/bin/redis-benchmark ${REDIS_BENCHMARK_TEST_ARGS}
  fi
}


function run_memtier_test() {

  if [[ ! -x /usr/local/bin/memtier_benchmark ]]; then
    log "/usr/local/bin/memtier_benchmark not found"
  elif [[ -z "${MEMTIER_TEST_ARGS}" ]]; then
    log "memtier-benchmark not configured (var MEMTIER_TEST_ARGS empty)"
  else
    log "Starting memtier_benchmark test"
    /usr/local/bin/memtier_benchmark ${MEMTIER_TEST_ARGS}
  fi
}


function run_all_combined_envoy_tests() {
  # This is where all combined Envoy tests (not merely connectivity tests,
  # like in wait_till_backend_db_is_up()) are run.
  # Comment one of the tests below if not necessary for stress testing and
  # code coverage.

  get_all_envoy_stats "Envoy stats before memtier tests"

  run_redis_benchmark_test

  get_all_envoy_stats "Envoy stats after redis-benchmark"

  run_memtier_test

  get_all_envoy_stats "Envoy stats after redis memtier_benchmark"
}

