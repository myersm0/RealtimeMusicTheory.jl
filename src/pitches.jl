
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

struct PitchClass{L <: LetterName, A <: Accidental} end

struct Pitch{PC <: PitchClass, Oct} end

PitchClass(::Type{L}, ::Type{A}) where {L <: LetterName, A <: Accidental} = 
    PitchClass{L, A}()

PitchClass(::Type{L}) where {L <: LetterName} = 
    PitchClass{L, Natural}()

Pitch(::Type{PC}, octave::Int) where {PC <: PitchClass} = 
    Pitch{PC, octave}()

Pitch(::Type{L}, ::Type{A}, octave::Int) where {L <: LetterName, A <: Accidental} = 
    Pitch{PitchClass{L, A}, octave}()

Pitch(::Type{L}, octave::Int) where {L <: LetterName} = 
    Pitch{PitchClass{L, Natural}, octave}()

# ===== accessors =====

letter(::Type{PitchClass{L, A}}) where {L, A} = L
accidental(::Type{PitchClass{L, A}}) where {L, A} = A

@generated function letter(::Type{Pitch{PC, Oct}}) where {PC, Oct}
    L = PC.parameters[1]
    :($L)
end

@generated function accidental(::Type{Pitch{PC, Oct}}) where {PC, Oct}
    A = PC.parameters[2]
    :($A)
end

octave(::Type{Pitch{PC, Oct}}) where {PC, Oct} = Oct
pitch_class(::Type{Pitch{PC, Oct}}) where {PC, Oct} = PC

letter(pc::PitchClass{L, A}) where {L, A} = L
accidental(pc::PitchClass{L, A}) where {L, A} = A
letter(p::Pitch{PC, Oct}) where {PC, Oct} = letter(PC)
accidental(p::Pitch{PC, Oct}) where {PC, Oct} = accidental(PC)
octave(p::Pitch{PC, Oct}) where {PC, Oct} = Oct
pitch_class(p::Pitch{PC, Oct}) where {PC, Oct} = PC

# ===== Compile-time lookups =====

letter_position(::Type{C}) = 0
letter_position(::Type{D}) = 1
letter_position(::Type{E}) = 2
letter_position(::Type{F}) = 3
letter_position(::Type{G}) = 4
letter_position(::Type{A}) = 5
letter_position(::Type{B}) = 6

letter_semitone(::Type{C}) = 0
letter_semitone(::Type{D}) = 2
letter_semitone(::Type{E}) = 4
letter_semitone(::Type{F}) = 5
letter_semitone(::Type{G}) = 7
letter_semitone(::Type{A}) = 9
letter_semitone(::Type{B}) = 11

accidental_offset(::Type{Natural}) = 0
accidental_offset(::Type{Sharp}) = 1
accidental_offset(::Type{Flat}) = -1
accidental_offset(::Type{DoubleSharp}) = 2
accidental_offset(::Type{DoubleFlat}) = -2

# ===== operations =====

@generated function semitone(::Type{PitchClass{L, A}}) where {L, A}
    semi = letter_semitone(L) + accidental_offset(A)
    :($semi)
end

@generated function letter_position(::Type{PitchClass{L, A}}) where {L, A}
    pos = letter_position(L)
    :($pos)
end

@generated function semitone(::Type{Pitch{PC, Oct}}) where {PC, Oct}
    # Get PitchClass semitone at compile time
    pc_semi = semitone(PC)
    total = pc_semi + 12 * (Oct + 1)
    :($total)
end

@generated function letter_position(::Type{Pitch{PC, Oct}}) where {PC, Oct}
    pos = letter_position(PC)
    :($pos)
end

semitone(pc::PitchClass) = semitone(typeof(pc))
semitone(p::Pitch) = semitone(typeof(p))
letter_position(pc::PitchClass) = letter_position(typeof(pc))
letter_position(p::Pitch) = letter_position(typeof(p))

# ===== Common pitch classes =====

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

