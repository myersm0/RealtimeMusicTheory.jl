# RealtimeMusicTheory
Fast, compile-time music theory primitives to support real-time audio applications in Julia.
- Zero allocations for core operations
- Compile-time computation of intervals, scales, and chords
- Type-stable throughout
- Real-time safe - no garbage collection pauses

I'd like to acknowledge dpsanders's very nice package [MusicTheory.jl](https://github.com/JuliaMusic/MusicTheory.jl), on which the current API is largely based. I decided to rethink his implementation from the ground up, however, in the interest of maximizing performance to support a real-time music application I'm building.

## Installation
```julia
using Pkg
Pkg.add("RealtimeMusicTheory")
```

## Usage
```julia
using RealtimeMusicTheory

# Create pitches
middle_c = Pitch(C, 4)

# Add intervals
e = middle_c + MajorThird()
g = middle_c + PerfectFifth()

# Build chords
c_major = majortriad(middle_c)
a_minor = minortriad(Pitch(A, 3))

# Create scales
scale = Scale(middle_c, MajorScale)
third_degree = scale[3]  # E4

# Calculate frequencies
a4 = Pitch(A, 4)
diapason = 440.0
temperament = EqualTemperament(a4, diapason)
freq = frequency(temperament, middle_c)  # ≈ 261.63 Hz
```

## License
MIT

[![Build Status](https://github.com/myersm0/RealtimeMusicTheory.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/myersm0/RealtimeMusicTheory.jl/actions/workflows/CI.yml?query=branch%3Amain)
