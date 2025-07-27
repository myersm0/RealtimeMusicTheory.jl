
# Pitch space types
abstract type PitchSpace end
struct DiatonicSpace <: PitchSpace end
struct ChromaticSpace <: PitchSpace end

Base.length(::Type{DiatonicSpace}) = 7
Base.length(::Type{ChromaticSpace}) = 12

# Step types
abstract type Step end

# Chromatic steps (semitones)
struct ChromaticStep{N} <: Step end

# Diatonic steps (letter names)
struct DiatonicStep{N} <: Step end

# Generic interval (will be defined as scale steps)
struct GenericInterval{N} <: Step end

# Common aliases
const Semitone = ChromaticStep{1}
const WholeTone = ChromaticStep{2}

