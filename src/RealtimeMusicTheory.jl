module RealtimeMusicTheory

include("pitches.jl")
export Accidental, Natural, Sharp, Flat, DoubleSharp, DoubleFlat, ♮, ♯, ♭, 𝄪, 𝄫
export LetterName, GenericPitchClass, GPC, PitchClass, Pitch
export letter, accidental, register, pitch_class
export C♮, C♯, D♭, D♮, D♯, E♭, E♮, E♯, F♭, F♮, F♯, G♭, G♮, G♯, A♭, A♮, A♯, B♭, B♮, B♯, C♭
export C𝄫, D𝄫, E𝄫, F𝄫, G𝄫, A𝄫, B𝄫, C𝄪, D𝄪, E𝄪, F𝄪, G𝄪, A𝄪, B𝄪
export C, D, E, F, G, A, B

include("traits.jl")

include("space_defs.jl")
include("space_ops.jl")
export MusicalSpace, GenericSpace, SignedSpace
export TopologyStyle, Linear, Circular
export Direction, LinearDirection, Left, Right, CircularDirection, Clockwise, Counterclockwise
export distance, direction
export LetterSpace, GenericFifthsSpace, GenericThirdsSpace, PitchClassSpace, LineOfFifths, CircleOfFifths
export is_enharmonic

include("intervals.jl")
include("arithmetic.jl")

end
