module RealtimeMusicTheory

include("pitches.jl")
export Accidental, Natural, Sharp, Flat, DoubleSharp, DoubleFlat, ♮, ♯, ♭, 𝄪, 𝄫
export LetterName, GenericPitchClass, GPC, PitchClass, Pitch
export letter, accidental, register, pitch_class
export C♮, C♯, D♭, D♮, D♯, E♭, E♮, E♯, F♭, F♮, F♯, G♭, G♮, G♯, A♭, A♮, A♯, B♭, B♮, B♯, C♭
export C𝄫, D𝄫, E𝄫, F𝄫, G𝄫, A𝄫, B𝄫, C𝄪, D𝄪, E𝄪, F𝄪, G𝄪, A𝄪, B𝄪
export C, D, E, F, G, A, B
export sharpen, flatten, modify

include("traits.jl")
export SpellingStyle, GenericSpelling, SpecificSpelling
export RegisterStyle, ClassLevel, Registral
export TopologyStyle, Linear, Circular
export Direction, LinearDirection, Left, Right, CircularDirection, Clockwise, Counterclockwise

include("space_defs.jl")
export MusicalSpace, DiscreteSpace, ContinuousSpace
export LetterSpace, GenericFifthsSpace, GenericThirdsSpace, LineOfFifths, CircleOfFifths
export PitchClassSpace, DiscretePitchSpace

include("space_ops.jl")
export distance, direction, is_enharmonic, find_enharmonics

include("intervals.jl")
export IntervalQuality, Perfect, Major, Minor, Augmented, Diminished
export AbstractInterval, GenericInterval, SpecificInterval, Interval
export P1, m2, M2, m3, M3, P4, A4, d5, P5, m6, M6, m7, M7, P8

include("arithmetic.jl")

end
