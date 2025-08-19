# RealtimeMusicTheory
Fast, compile-time music theory abstractions to support real-time audio applications in Julia. I have aimed for:
- Zero-allocations
- Compile-time computation of intervals and pitch relationships
- Type-stable operations throughout
- Real-time safe - no garbage collection pauses

What this means is that all operations _should be_ virtually free at runtime -- less than 1 nanosecond on my machine. With the core design of the package out of the way now, I will be evaluating to what extent I’ve met this goal, how it holds up under real-world usage, and how to address any shortcomings. Notably, there is a negligible compilation overhead the first time you call a function with a given combination of types.

This package was originally intended to be a feature-complete reimplementation of dpsanders's very nice package [MusicTheory.jl](https://github.com/JuliaMusic/MusicTheory.jl), but has since diverged significantly in scope and design. RealtimeMusicTheory centers around the concept of `Pitches` and their organization into MusicalSpaces, specifically _discrete_ spaces, that provide different ways of organizing and navigating pitch relationships. As of version 0.3, I have temporarily dropped support of scale- and chord-related structures, to focus instead on the core building blocks for the time being; but I expect these structures to return in a later version.

I would like to add that I'm not an expert in music theory myself, but have strived for theoretically correct operations and terminology here. I have largely relied on Julian Hook's book _Exploring Musical Spaces_ (Oxford University Press, 2022) as a reference.

## Installation
In Julia 1.9 or greater:
```julia
using Pkg
Pkg.add("RealtimeMusicTheory")
```

## Usage
```julia
using RealtimeMusicTheory
```

### Basic pitch representations

A PitchClass is a note name with optional accidental, but lacking octave/register info:
```julia
c = PitchClass(C)
c_sharp = PitchClass(C, Sharp)
d_flat = PitchClass(D, Flat)

# Unicode accidentals are also supported
c_sharp = C♯
d_flat = D♭
e_double_sharp = E𝄪

# You can specify an arbitrary number of accidentals:
c_triple_sharp = PitchClass(C, Accidental(3))
c_triple_flat = PitchClass(C, Accidental(-3))
```

A Pitch, by contrast, is the realization of a PitchClass _in a specific octave/register_. For example, middle C lies in the 4th register:
```julia
middle_c = Pitch(C, 4)        # or Pitch(C♮, 4) or C♮[4]
```

### Interval arithmetic

Add intervals to pitches or pitch classes:
```julia
middle_c + M3  # major third (E♮[4])
middle_c + m3  # minor third (E♭[4])
middle_c + P5  # perfect fifth (G♮[4])
middle_c + P8  # octave (C♮[5])
```

Shorthands for common intervals (P1, m2, M2, m3, M3, P4, A4, d5, P5, m6, M6, m7, M7, P8) are predefined, but you can construct any _valid_ interval like this:
```julia
c5 = middle_c + Interval(9, Major)    # major 9th
c6 = middle_c + Interval(15, Perfect)  # two octaves
```

Compute intervals between pitches:
```julia
Interval(C♮[4], E♮[4])  # M3 (major third)
Interval(C♮[4], G♭[4])  # d5 (diminished fifth)
```

### MusicalSpaces

The core abstraction in RealtimeMusicTheory is the `MusicalSpace`. Different spaces provide different ways to organize and navigate pitches.

MusicalSpaces can be classified by three traits: 
- `TopologyStyle`
	- A `Circular` topology indicates that the space can be traversed in two directions, `Clockwise` or `Counterclockwise`, with wraparound behavior when you reach the "ends." 
	- In a `Linear` space, by contrast, there is only one path from any point A to another point B: either from the `Left` or from the `Right`. (For convenience, but somewhat counterintuitively, wraparound indexing is also implemented for Linear spaces.)
- `SpellingStyle`
	- A space with `GenericSpelling` uses bare letter names, without accidentals
	- A space with `SpecificSpelling` recognizes accidentals
- `RegisterStyle`
	- A `ClassLevel` space operates at the level of the PitchClass or LetterName, i.e. without register/octave information
	- A `Registral` space operates at the level of the Pitch, i.e. with designations of register/octave

```julia
# LetterSpace - containing the 7 letter names in order:
distance(LetterSpace, C, E)  # 2 (C→D→E)
distance(LetterSpace, B, D)  # 2 (shortest path wraps: B→C→D)

# Circle of Fifths - containing the 12 chromatic pitch classes arranged by perfect fifths:
distance(CircleOfFifths, C♮, G♮)  # 1 (one step clockwise)
distance(CircleOfFifths, C♮, F♮)  # 1 (one step counterclockwise)

# Line of Fifths - an infinite bidirectional Linear space sequence of perfect fifths{
distance(LineOfFifths, C♮, C♯)    # 7 (seven fifths up: C→G→D→A→E→B→F♯→C♯)
direction(LineOfFifths, C♮, F♮)   # Left (F is to the left of C)

# Pitch Class Space - chromatic space (12 semitones)
distance(PitchClassSpace, C♮, D♯) # 3 semitones
```

### Space iteration and indexing

MusicalSpaces support a range-like syntax for generating sequences of pitches:
```julia
# Basic range: start position, length
CircleOfFifths(C♮, 12) |> collect  # All 12 pitch classes in fifths order
LetterSpace(D, 5) |> collect       # [D, E, F, G, A]

# Start to stop (inclusive)
CircleOfFifths(C♮, F♮) |> collect  # [C♮, G♮, D♮, A♮, E♮, B♮, F♯, C♯, G♯, D♯, A♯, F♮]
LetterSpace(C, E) |> collect       # [C, D, E]

# With step size: start, step, length
PitchClassSpace(C♮, 2, 6) |> collect   # whole tones: [C♮, D♮, E♮, F♯, G♯, A♯]
PitchClassSpace(C♮, 3, 4) |> collect   # minor thirds: [C♮, E♭, G♭, A]
CircleOfFifths(C♮, -1, 5) |> collect   # descending fifths: [C♮, F♮, B♭, E♭, A♭]

# Start, step, stop
PitchClassSpace(C♮, 4, B♮) |> collect  # major thirds: [C♮, E♮, G♯]
LetterSpace(C, 2, B) |> collect        # every other letter: [C, E, G, B]
```

You can use arithmetic expressions with pitch classes to specify positions relative to known pitches:
```julia
# Start from one position before/after a specified note
CircleOfFifths(C♮ - 1, 3) |> collect   # start from F♮: [F♮, C♮, G♮]
CircleOfFifths(G♮ + 1, 3) |> collect   # start from D♮: [D♮, A♮, E♮]

# Expressions are supported for both the `start` and `stop` arguments:
PitchClassSpace(C♮, D♯ + 1) |> collect       # C through E: [C♮, C♯, D♮, D♯, E♮]
CircleOfFifths(F♮ + 1, C♮ - 1) |> collect    # C♮ through F♮ the long way
```


### Enharmonic relationships

Find and test enharmonic equivalences:
```julia
is_enharmonic(C♯, D♭)  # true
is_enharmonic(E♯, F♮)  # true

# Find the first 5 enharmonic spellings of a given PitchClass
# (results will be sorted by the most standard spelling first -- i.e. fewest accidentals)
find_enharmonics(C♮, 5)  # C♮, B♯, D♭♭, A♯♯♯, E♭♭♭♭
```


## License
MIT

[![Build Status](https://github.com/myersm0/RealtimeMusicTheory.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/myersm0/RealtimeMusicTheory.jl/actions/workflows/CI.yml?query=branch%3Amain)
