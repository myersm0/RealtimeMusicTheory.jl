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

include("steps.jl")
export PitchSpace, DiatonicSpace, ChromaticSpace
export Step, DiatonicStep, ChromaticStep, GenericInterval, Semitone, WholeTone
export Interval, IntervalQuality, Perfect, Major, Minor, Augmented, Diminished
export P1, m2, M2, m3, M3, P4, A4, d5, P5, m6, M6, m7, M7, P8

include("musical_structures.jl")

include("scales.jl")
export AbstractScale, DiatonicScale, ChromaticScale
export MajorScale, MinorScale, NaturalMinorScale, MelodicMinorScale, HarmonicMinorScale
export Scale, ScaleDegree, ScaleFunction
export Tonic, Supertonic, Mediant, Subdominant, Dominant, Submediant, LeadingTone, SubTonic
export tonic, supertonic, mediant, subdominant, dominant, submediant, leadingtone, subtonic
export realize

include("arithmetic.jl")

include("chords.jl")
export Chord, triad, quality

include("show.jl")

end
