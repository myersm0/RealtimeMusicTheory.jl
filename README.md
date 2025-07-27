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
```
using RealtimeMusicTheory

# Create pitches using type constructors
middle_c = Pitch(C, 4)
c_sharp = Pitch(C, Sharp, 4)  # or Pitch(C, ♯, 4) or Pitch(C♯, 4)
d_flat = Pitch(D, Flat, 4)    # or Pitch(D, ♭, 4) or Pitch(D♭, 4)

# Interval arithmetic
e4 = middle_c + M3       # Major third
e_flat4 = middle_c + m3  # Minor third
g4 = middle_c + P5       # Perfect fifth
c5 = middle_c + P8       # Octave

# Chromatic and diatonic steps
c_sharp4 = middle_c + ChromaticStep{1}   # One semitone up
c_sharp4 = middle_c + ChromaticStep{-1}  # One semitone down
d4 = middle_c + DiatonicStep{1}          # One letter name up
b4 = middle_c + DiatonicStep{-1}         # One letter name up

# Scales
c_major = Scale(MajorScale, PitchClass(C))
d_minor = Scale(MinorScale, PitchClass(D))
d_harmonic_minor = Scale(HarmonicMinorScale, PitchClass(D))

# Access scale degrees
tonic = c_major[ScaleDegree{1}]        # C
dominant = c_major[ScaleDegree{5}]     # G
leading_tone = c_major[ScaleDegree{7}] # B

# Build triads from scales
c_triad = triad(c_major, ScaleDegree{1})  # C major triad
d_triad = triad(c_major, ScaleDegree{2})  # D minor triad

# Conversion to MIDI note numbers
midi_middle_c = semitone(middle_c)  # 60
midi_a440 = semitone(Pitch(A, 4))   # 69
```

## License
MIT

[![Build Status](https://github.com/myersm0/RealtimeMusicTheory.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/myersm0/RealtimeMusicTheory.jl/actions/workflows/CI.yml?query=branch%3Amain)
