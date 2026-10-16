#pragma once
#include <chrono>
#include <vector>
#include <algorithm>
#include <iostream>
#include <string>

namespace proai77::bench {

struct BenchResult {
    std::string name;
    size_t iterations;
    double p50_us;
    double p90_us;
    double p99_us;
    double min_us;
    double max_us;
};

template <typename Func>
BenchResult benchmark(const std::string& name, Func&& func, size_t warmup = 10, size_t iterations = 100) {
    // Warmup phase
    for (size_t i = 0; i < warmup; ++i) {
        func();
    }

    std::vector<double> timings;
    timings.reserve(iterations);

    for (size_t i = 0; i < iterations; ++i) {
        auto t0 = std::chrono::steady_clock::now();
        func();
        auto t1 = std::chrono::steady_clock::now();
        double us = std::chrono::duration<double, std::micro>(t1 - t0).count();
        timings.push_back(us);
    }

    std::sort(timings.begin(), timings.end());

    BenchResult res;
    res.name = name;
    res.iterations = iterations;
    res.min_us = timings.front();
    res.max_us = timings.back();
    res.p50_us = timings[iterations * 50 / 100];
    res.p90_us = timings[iterations * 90 / 100];
    res.p99_us = timings[iterations * 99 / 100];

    std::cout << "[BENCHMARK: " << res.name << " (" << res.iterations << " runs)]\n"
              << "  Min: " << res.min_us << " us | P50: " << res.p50_us << " us\n"
              << "  P90: " << res.p90_us << " us | P99: " << res.p99_us << " us\n"
              << "  Max: " << res.max_us << " us\n";

    return res;
}

} // namespace proai77::bench
