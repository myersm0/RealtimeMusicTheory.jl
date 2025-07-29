# RealtimeMusicTheory
Fast, compile-time music theory primitives to support real-time audio applications in Julia.
- Zero allocations for core operations
- Compile-time computation of intervals, scales, and chords
- Type-stable throughout
- Real-time safe - no garbage collection pauses

What this means is that all operations are virtually _free_ at runtime -- less than 1 nanosecond on my machine. There is, however, a negligible precompilation overhead the first time you call a function with a given combination of types.

I'd like to acknowledge dpsanders's very nice package [MusicTheory.jl](https://github.com/JuliaMusic/MusicTheory.jl), on which the current API is largely based. I decided to rethink his implementation from the ground up, however, in the interest of maximizing performance to support a real-time music application I'm building.

## Installation
```julia
using Pkg
Pkg.add("RealtimeMusicTheory")
```

## Usage
```
using RealtimeMusicTheory
```
A PitchClass is a note name with optional accidental, but lacking octave/register info:
```
c = PitchClass(C)
c_sharp = PitchClass(C, Sharp)
```

A Pitch contains register info, to tie it to a specific MIDI note or a specific key on the keyboard:
```
middle_c = Pitch(C, 4)
c_sharp = Pitch(C, Sharp, 4)  # or Pitch(C, ♯, 4) or Pitch(C♯, 4)
d_flat = Pitch(D, Flat, 4)    # or Pitch(D, ♭, 4) or Pitch(D♭, 4)
```

Interval arithmetic:
```
middle_c + M3  # major third (E)
middle_c + m3  # minor third (E-flat)
middle_c + P5  # perfect fifth (G)
middle_c + P8  # octave (C)
```
Shorthands M3, P8, etc are defined for common intervals up through P8 (a perfect 8th AKA octave), but you can specify arbitrary intervals via this slightly more verbose syntax:
```
d5 = middle_c + Interval(9, Major)
c6 = middle_c + Interval(15, Perfect)
```

Chromatic and diatonic steps:
```
middle_c + ChromaticStep(1)   # one semitone up (C#)
middle_c + ChromaticStep(-1)  # one semitone down (B)
middle_c + DiatonicStep(1)    # one letter name up (D)
middle_c + DiatonicStep(-1)   # one letter name down (B)
```

Scales:
```
c_major = Scale(MajorScale, PitchClass(C))
d_minor = Scale(NaturalMinorScale, PitchClass(D))
d_harmonic_minor = Scale(HarmonicMinorScale, PitchClass(D))
d_melodmic_minor = Scale(MelodicMinorScale, PitchClass(D))

c_major[ScaleDegree(1)]  # C
c_major[ScaleDegree(5)]  # G
c_major[ScaleDegree(7)]  # B

# or equivalently:
c_major[Tonic]
c_major[Dominant]
c_major[LeadingTone]
```

Chords (limited support so far; more coming soon):
```
c_triad = triad(c_major, ScaleDegree(1))  # C major triad
d_triad = triad(c_major, ScaleDegree(2))  # d minor triad
```

Conversion to MIDI note numbers
```
midi_middle_c = semitone(middle_c)  # 60
midi_a440 = semitone(Pitch(A, 4))   # 69
```

## License
MIT

[![Build Status](https://github.com/myersm0/RealtimeMusicTheory.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/myersm0/RealtimeMusicTheory.jl/actions/workflows/CI.yml?query=branch%3Amain)
