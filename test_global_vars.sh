#!/bin/bash
#
# Global constants and variables for tests on an Envoy proxy with a Redis
# upstream database.

declare -r DURATION_TESTS=$(( 1 * 60 ))

# Redis MemTier-Benchmark arguments:

declare -r MEMTIER_MIN_ARGS="--protocol=$DRIVER
                             --server=${ENVOY_HOST}
                             --port=${ENVOY_PROXY_PORT}"

declare -r MEMTIER_CONN_PING_TEST_ARGS="${MEMTIER_MIN_ARGS}
                                        --command=PING
                                        --run-count=1
                                        --requests=1
                                        --clients=1
                                        --threads=1
                                        --hide-histogram"

declare -r MEMTIER_TEST_ARGS="${MEMTIER_MIN_ARGS}
                              --show-config
                              --randomize
                              --threads=4
                              --test-time=${DURATION_TESTS}
                              --random-data
                              --data-size-range=1-5000
                              --data-size-pattern=R"

declare -r REDIS_BENCHMARK_TEST_ARGS="-h ${ENVOY_HOST}
                                      -p ${ENVOY_PROXY_PORT}
                                      -t set,get,del
                                      --threads 4
                                      -c 100
                                      -n 1000000
                                      -d 64
                                      -k 1
                                      -k 10000000
                                      -q"

