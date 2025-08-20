using BenchmarkTools
using RealtimeMusicTheory
using InteractiveUtils

import RealtimeMusicTheory: semitones, offset, number

const SUITE = BenchmarkGroup()

SUITE["core"] = BenchmarkGroup()

benchmarks = ["naive", "realistic"]
for b in benchmarks
	include("$b.jl")
end


