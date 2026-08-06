# RealtimeMusicTheory
Fast, compile-time music theory abstractions to support real-time audio applications in Julia. I have aimed for:
- Allocation-free scalar operations on pitches, pitch classes, and intervals
- Compile-time computation of intervals and pitch relationships
- Type-stable operations throughout
- Real-time safe once warmed up, for a bounded vocabulary of pitch and interval types

Pitches, intervals, and spaces are all encoded as types, so the work happens during compilation and the scalar operations reduce to constants at the call site. The cost is moved rather than removed: each new combination of types you touch is compiled the first time it is used, so the guarantees above hold after warm-up and for a set of types your application uses repeatedly. Open-ended runtime data -- pitches whose exact type is not known statically, or heterogeneous collections of them -- will not see the same benefit.

A few operations allocate by design and are not real-time safe: `I^n` builds a vector of intervals, and `find_enharmonics` sorts. Both are intended for setup rather than the audio thread.

With the core design of the package out of the way now, I am working on characterizing the above more rigorously; the numbers in `benchmark/` should be read as provisional.

This package was originally intended to be a feature-complete reimplementation of dpsanders's very nice package [MusicTheory.jl](https://github.com/JuliaMusic/MusicTheory.jl), but has since diverged significantly in scope and design. RealtimeMusicTheory centers around the concept of pitches and their organization into MusicalSpaces, specifically _discrete_ spaces, that provide different ways of organizing and navigating pitch relationships. As of version 0.3, I have temporarily dropped support of scale- and chord-related structures, to focus instead on the core building blocks for the time being; but I expect these structures to return in a later version.

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
middle_c = Pitch(60)          # equivalently, using a MIDI number 60 (middle C)
```

### Interval arithmetic

Add intervals to pitches or pitch classes:
```julia
middle_c + M3  # major third (E♮[4])
middle_c + m3  # minor third (E♭[4])
middle_c + P5  # perfect fifth (G♮[4])
middle_c + P8  # octave (C♮[5])
```

Subtraction transposes downward by the same interval:
```julia
middle_c - M3  # A♭[3]
middle_c - P5  # F♮[3]
middle_c - P8  # C♮[3]
```

An interval here is an unsigned magnitude and the operator supplies the direction; there is no descending `SpecificInterval`, and arithmetic between two intervals is not defined. Correspondingly, `Interval(P1, P2)` requires that `P2` lie at or above `P1` in letter-and-register order, and errors otherwise.

Shorthands for common intervals (P1, m2, M2, m3, M3, P4, A4, d5, P5, m6, M6, m7, M7, P8) are predefined, but you can construct any _valid_ interval like this:
```julia
middle_c + Interval(9, Major)    # major 9th
middle_c + Interval(15, Perfect)  # two octaves
```

Compute intervals between pitches:
```julia
julia> Interval(C♮[4], E♮[4])
M3 (alias for SpecificInterval{3, Major})

julia> Interval(C♮[4], G♭[4])
d5 (alias for SpecificInterval{5, Diminished})

julia> Interval(C♮[4], B♯[4])
SpecificInterval{7, Augmented}
```

The interval number follows written letter and register, independently of how the pitches sound: `B♯[4]` and `C♮[5]` are the same key on a piano, but lie a seventh and an octave above `C♮[4]` respectively.

Concatenated repetition of intervals is also defined similar to string repetitions in base Julia. For example, to raise middle C by two octaves:
```julia
julia> Pitch(C♮, 4) + P8^2
Pitch{C♮, 6}
```

This could be useful for concisely generating [Tonnetz](https://en.wikipedia.org/wiki/Tonnetz) spaces. For example, to generate a small Tonnetz by minor thirds along the rows and major thirds along the columns:
```julia
julia> tonnetz = [B♭ + M3^i + m3^j for i in 4:-1:0, j in 0:4]
5×5 Matrix{DataType}:
 C𝄪  E♯  G♯  B♮  D♮
 A♯  C♯  E♮  G♮  B♭
 F♯  A♮  C♮  E♭  G♭
 D♮  F♮  A♭  C♭  E𝄫
 B♭  D♭  F♭  A𝄫  C𝄫
```

### MusicalSpaces

The core abstraction in RealtimeMusicTheory is the `MusicalSpace`. Different spaces provide different ways to organize and navigate pitches.

#### Motivation
Before discussing how to work with these spaces, I will first motivate their inclusion by showing how you can use them to extract useful musical facts. A key example is that the enharmonicity of two pitch classes (notwithstanding possible differences in tuning) can be determined by checking whether the distance between those two notes, on the line of fifths, is a multiple of 12. The following is the one-liner constituting this package's `is_enharmonic()` function, to be described later. Given two pitch classes PC1 and PC2, enharmonicity is determined by simply evaluating:
```
mod(distance(LineOfFifths, PC1, PC2), 12) == 0
```

#### Traits
MusicalSpaces can be classified by three traits: 
- TopologyStyle
	- A Circular topology indicates that the space can be traversed in two directions, Clockwise or Counterclockwise, with wraparound behavior when you reach the "ends." 
	- In a Linear space, by contrast, there is only one path from any point A to another point B: either from the Left or from the Right. Linear spaces here are infinite in both directions, so there are no "ends" to wrap around.
- SpellingStyle
	- A space with GenericSpelling uses bare letter names, without accidentals
	- A space with SpecificSpelling recognizes accidentals
- RegisterStyle
	- A ClassLevel space operates at the level of the PitchClass or LetterName, i.e. without register/octave information
	- A Registral space operates at the level of the Pitch, i.e. with designations of register/octave

#### Cardinality
Finite spaces report their size through `cardinality`, which is also what `Base.length` returns for them. Infinite spaces error, so check `Base.isfinite` first if you don't know which you have.
```julia
cardinality(LetterSpace)     # 7
cardinality(CircleOfFifths)  # 12
Base.isfinite(LineOfFifths)  # false
```

#### Distance and direction
The traits described above enable querying spaces to check the distance between two elements, and the direction of the path from one to the other (Left/Right or Clockwise/Counterclockwise). Directional distance in a circular space is measured the whole way round in the direction asked for, so it is not symmetric.
```julia
# LetterSpace - containing the 7 letter names in order:
distance(LetterSpace, C, E)  # 2 (C→D→E)
distance(LetterSpace, B, D)  # 2 (shortest path wraps: B→C→D)

# Circle of Fifths - containing the 12 chromatic pitch classes arranged by perfect fifths:
distance(CircleOfFifths, C♮, G♮)  # 1 (one step clockwise)
distance(CircleOfFifths, C♮, F♮)  # 1 (one step counterclockwise)

# Line of Fifths - an infinite bidirectional Linear space of perfect fifths
distance(LineOfFifths, C♮, C♯)    # 7 (seven fifths up: C→G→D→A→E→B→F♯→C♯)
direction(LineOfFifths, C♮, F♮)   # Left (F is to the left of C)

# Pitch Class Space - chromatic space (12 semitones)
distance(PitchClassSpace, C♮, D♯) # 3 semitones

# a direction may be given explicitly in a circular space:
distance(CircleOfFifths, Clockwise, C♮, F♮)         # 11
distance(CircleOfFifths, Counterclockwise, C♮, F♮)  # 1
```

#### Space iteration and indexing

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
PitchClassSpace(C♮, 3, 4) |> collect   # minor thirds: [C♮, D♯, F♯, A♮]
CircleOfFifths(C♮, -1, 5) |> collect   # descending fifths: [C♮, F♮, A♯, D♯, G♯]

# Start, step, stop
PitchClassSpace(C♮, 4, B♮) |> collect  # major thirds: [C♮, E♮, G♯]
LetterSpace(C, 2, B) |> collect        # every other letter: [C, E, G, B]
```

Note that `PitchClassSpace` and `CircleOfFifths` each hold one fixed representative per position, spelled with sharps where a choice exists, and generated ranges index those representatives directly. A descending run through `CircleOfFifths` therefore yields `A♯, D♯, G♯` rather than the `B♭, E♭, A♭` that a musician would write. Spelling that follows the direction of travel or a key context would require a policy these spaces deliberately do not carry; use `find_enharmonics` to respell.

When the second argument is a number it is read as a length, not as a stop position, so a stop must be given as a pitch class, letter name, or arithmetic expression.

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
find_enharmonics(C♮, 5)  # C♮, B♯, D𝄫, A♯♯♯, E♭♭♭♭
```


## License
MIT

[![Build Status](https://github.com/myersm0/RealtimeMusicTheory.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/myersm0/RealtimeMusicTheory.jl/actions/workflows/CI.yml?query=branch%3Amain)
