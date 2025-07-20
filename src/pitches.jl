
abstract type LetterName end
struct C <: LetterName end
struct D <: LetterName end
struct E <: LetterName end
struct F <: LetterName end
struct G <: LetterName end
struct A <: LetterName end
struct B <: LetterName end

abstract type Accidental end
struct Natural <: Accidental end
struct Sharp <: Accidental end
struct Flat <: Accidental end
struct DoubleSharp <: Accidental end
struct DoubleFlat <: Accidental end

const ♮ = Natural
const ♯ = Sharp
const ♭ = Flat
const 𝄪 = DoubleSharp
const 𝄫 = DoubleFlat

struct PitchClass{Letter <: LetterName, Acc <: Accidental} end

PitchClass(::Type{L}, ::Type{A}) where {L <: LetterName, A <: Accidental} = 
    PitchClass{L, A}()

PitchClass(::Type{L}) where {L <: LetterName} = 
    PitchClass{L, Natural}()

const C♮ = PitchClass{C, Natural}
const C♯ = PitchClass{C, Sharp}
const D♭ = PitchClass{D, Flat}
const D♮ = PitchClass{D, Natural}
const D♯ = PitchClass{D, Sharp}
const E♭ = PitchClass{E, Flat}
const E♮ = PitchClass{E, Natural}
const E♯ = PitchClass{E, Sharp}
const F♭ = PitchClass{F, Flat}
const F♮ = PitchClass{F, Natural}
const F♯ = PitchClass{F, Sharp}
const G♭ = PitchClass{G, Flat}
const G♮ = PitchClass{G, Natural}
const G♯ = PitchClass{G, Sharp}
const A♭ = PitchClass{A, Flat}
const A♮ = PitchClass{A, Natural}
const A♯ = PitchClass{A, Sharp}
const B♭ = PitchClass{B, Flat}
const B♮ = PitchClass{B, Natural}
const B♯ = PitchClass{B, Sharp}
const C♭ = PitchClass{C, Flat}

struct Pitch{PC <: PitchClass, Oct} end

Pitch(::Type{PC}, octave::Int) where {PC <: PitchClass} = 
    Pitch{PC, octave}()

Pitch(::Type{L}, ::Type{A}, octave::Int) where {L <: LetterName, A <: Accidental} = 
    Pitch{PitchClass{L, A}, octave}()

Pitch(::Type{L}, octave::Int) where {L <: LetterName} = 
    Pitch{PitchClass{L, Natural}, octave}()

# Base semitones for natural notes
semitone(::Type{C}) = 0
semitone(::Type{D}) = 2
semitone(::Type{E}) = 4
semitone(::Type{F}) = 5
semitone(::Type{G}) = 7
semitone(::Type{A}) = 9
semitone(::Type{B}) = 11

# Accidental modifications
offset(::Type{Natural}) = 0
offset(::Type{Sharp}) = 1
offset(::Type{Flat}) = -1
offset(::Type{DoubleSharp}) = 2
offset(::Type{DoubleFlat}) = -2

letter(::Type{PitchClass{L, A}}) where {L, A} = L
accidental(::Type{PitchClass{L, A}}) where {L, A} = A

letter(::PitchClass{L, A}) where {L, A} = L

# Semitone calculation for pitch classes
@generated function semitone(::Type{PitchClass{L, A}}) where {L <: LetterName, A <: Accidental}
    base = semitone(L)
    acc_offset = offset(A)
    :($(base + acc_offset))
end

# Enable C♯[4] style notation
Base.getindex(pc::Type{<:PitchClass}, octave::Int) = Pitch{pc, octave}()


