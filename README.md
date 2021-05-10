# About

A docker-compose version of a benchmark on the Envoy proxy with Redis backend
using Redis-benchmark and MemTier-benchmark.

# WIP

This project is a *work in progress*. The implementation is *incomplete* and
subject to change. The documentation can be inaccurate.

# How to run:

In this directory, as a preparatory step, you need to create the directory
where the results be left:

      [[ ! -d ./proxy_results ]]   && \
           mkdir ./proxy_results   && \
           sudo chown root: ./proxy_results

Then, afterwards, in this directory, run:

      docker-compose pull
       
      docker-compose up --build -d

# Results left by a run:

The results of the tests will be left in the `proxy_results/` directory.
(If another directory is needed, please modify `docker-compose.yaml`.) The
result files left by each docker-compose up of the test containers are
(`<common_suffix>` below is a common suffix generated from the container-id
and initial epoch at the start of the docker-compose up, and is common among
all log files of the same run):

- envoy_redis_stats_<common_suffix>.log

The Envoy stats at the end of each Sysbench test, from `http://localhost:8001/stats`

- envoy_redis_log_<common_suffix>.log

The Envoy debug logs.

- script_redis_trace_<common_suffix>.log

The test script logs itself (contains Perf and SysBench messages).

- envoy_redis_perf_<common_suffix>.data

The Perf-Record file during the Sysbench tests.

- envoy_redis_perf_<common_suffix>.script.txt.xz

The Perf-Script text file generated (with symbol names) from the Perf-Record
file above.

# How to generate final flame graphs:

Note: To generate (externally, after the containers have run) the
[FlameGraph](https://github.com/brendangregg/FlameGraph), use the
`envoy_redis_perf_<common_suffix>.script.txt.xz` file with the symbol names:

       xzcat 'proxy_results/envoy_redis_perf_<common_suffix>.script.txt.xz' | \
            ${your_flamegraph_install_dir}/stackcollapse-perf.pl | \
            ${your_flamegraph_install_dir}/flamegraph.pl > envoy_flamegraph.svg

It is possible to run
[differential flame graphs for performance regression testing](http://www.brendangregg.com/blog/2014-11-09/differential-flame-graphs.html)
on two different versions of the same Envoy filter, e.g., in a continuous
integration (CI). See the argument `ENVOY_TAG_VERSION` in `Dockerfile-proxy`:

       ARG ENVOY_TAG_VERSION=latest
       FROM envoyproxy/envoy-debug-dev:$ENVOY_TAG_VERSION

, e.g., to do a performance regression testing between
`ENVOY_TAG_VERSION=85a8570cd0530402de21c48c6688dddb187775d5` and
`ENVOY_TAG_VERSION=6c672b75b1be59676bc5f576af96323e6c626a03`.

       xzcat 'proxy_results/envoy_redis_perf_<first_version>.script.txt.xz' | \
            ${your_flamegraph_install_dir}/stackcollapse-perf.pl  > v1.folded
        
       xzcat 'proxy_results/envoy_redis_perf_<second_version>.script.txt.xz' | \
            ${your_flamegraph_install_dir}/stackcollapse-perf.pl  > v2.folded
        
       ${your_flamegraph_install_dir}/difffolded.pl v1.folded v2.folded | \
            ${your_flamegraph_install_dir}/flamegraph.pl > perfrm_regr_test.svg

