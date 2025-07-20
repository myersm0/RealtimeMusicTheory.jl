module RealtimeMusicTheory

include("pitches.jl")
include("intervals.jl")
include("scales.jl")
include("chords.jl")

export Pitch, C, D, E, F, G, A, B
export Natural, Sharp, Flat, DoubleSharp, DoubleFlat, ♮, ♯, ♭, ♯♯, ♭♭
export Interval, Unison, MinorSecond, MajorSecond, MinorThird, MajorThird
export PerfectFourth, Tritone, PerfectFifth, MinorSixth, MajorSixth
export MinorSeventh, MajorSeventh, Octave
export Scale, degree, MajorScale, NaturalMinorScale
export Chord, majortriad, minortriad
export semitone, semitones, offset, next_note, scale_interval, degree
export majortriad, minortriad, is_major_triad, frequency
export EqualTemperament


