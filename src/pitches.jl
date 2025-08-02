
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
struct Pitch{PC <: PitchClass, Register} end

PitchClass(::Type{L}, ::Type{A}) where {L <: LetterName, A <: Accidental} = 
	PitchClass{L, A}

PitchClass(::Type{L}) where {L <: LetterName} = 
	PitchClass{L, Natural}

Pitch(::Type{PC}, register::Int) where {PC <: PitchClass} = 
	Pitch{PC, register}

Pitch(::Type{L}, ::Type{A}, register::Int) where {L <: LetterName, A <: Accidental} = 
	Pitch{PitchClass{L, A}, register}

Pitch(::Type{L}, register::Int) where {L <: LetterName} = 
	Pitch{PitchClass{L, Natural}, register}

const C♮ = PitchClass(C, Natural)
const C♯ = PitchClass(C, Sharp)
const D♭ = PitchClass(D, Flat)
const D♮ = PitchClass(D, Natural)
const D♯ = PitchClass(D, Sharp)
const E♭ = PitchClass(E, Flat)
const E♮ = PitchClass(E, Natural)
const E♯ = PitchClass(E, Sharp)
const F♭ = PitchClass(F, Flat)
const F♮ = PitchClass(F, Natural)
const F♯ = PitchClass(F, Sharp)
const G♭ = PitchClass(G, Flat)
const G♮ = PitchClass(G, Natural)
const G♯ = PitchClass(G, Sharp)
const A♭ = PitchClass(A, Flat)
const A♮ = PitchClass(A, Natural)
const A♯ = PitchClass(A, Sharp)
const B♭ = PitchClass(B, Flat)
const B♮ = PitchClass(B, Natural)
const B♯ = PitchClass(B, Sharp)
const C♭ = PitchClass(C, Flat)

# less common pitches that may be needed
const F𝄫 = PitchClass(B, DoubleFlat)
const C𝄫 = PitchClass(B, DoubleFlat)
const G𝄫 = PitchClass(B, DoubleFlat)
const E𝄫 = PitchClass(E, DoubleFlat)
const A𝄫 = PitchClass(A, DoubleFlat)
const D𝄫 = PitchClass(D, DoubleFlat)
const D𝄫 = PitchClass(D, DoubleFlat)
const F𝄪 = PitchClass(F, DoubleSharp)
const C𝄪 = PitchClass(C, DoubleSharp)
const G𝄪 = PitchClass(G, DoubleSharp)
const D𝄪 = PitchClass(D, DoubleSharp)
const A𝄪 = PitchClass(A, DoubleSharp)
const E𝄪 = PitchClass(E, DoubleSharp)
const B𝄪 = PitchClass(B, DoubleSharp)

letter(::Type{PitchClass{L, A}}) where {L, A} = L
accidental(::Type{PitchClass{L, A}}) where {L, A} = A
register(::Type{PitchClass{L, A}}) where {L, A} = nothing
pitch_class(::Type{PitchClass{L, A}}) where {L, A} = PitchClass(L, A)

letter(::Type{Pitch{PC, Register}}) where {PC, Register} = letter(PC)
accidental(::Type{Pitch{PC, Register}}) where {PC, Register} = accidental(PC)
register(::Type{Pitch{PC, Register}}) where {PC, Register} = Register
pitch_class(::Type{Pitch{PC, Register}}) where {PC, Register} = PC

letter_position(::Type{C}) = 0
letter_position(::Type{D}) = 1
letter_position(::Type{E}) = 2
letter_position(::Type{F}) = 3
letter_position(::Type{G}) = 4
letter_position(::Type{A}) = 5
letter_position(::Type{B}) = 6

chromatic_position(::Type{C}) = 0
chromatic_position(::Type{D}) = 2
chromatic_position(::Type{E}) = 4
chromatic_position(::Type{F}) = 5
chromatic_position(::Type{G}) = 7
chromatic_position(::Type{A}) = 9
chromatic_position(::Type{B}) = 11

offset(::Type{Natural}) = 0
offset(::Type{Sharp}) = 1
offset(::Type{Flat}) = -1
offset(::Type{DoubleSharp}) = 2
offset(::Type{DoubleFlat}) = -2

# Total semitones for a pitch class
@generated function semitone(::Type{PitchClass{L, A}}) where {L, A}
	semi = chromatic_position(L) + offset(A)
	return :($semi)
end

# Total semitones for a pitch (with octave)
@generated function semitone(::Type{Pitch{PC, Register}}) where {PC, Register}
	pc_semi = semitone(PC)
	register_adjustment = div(pc_semi, 12)
	semi_in_register = mod(pc_semi, 12)
	total = semi_in_register + 12 * (Register + register_adjustment + 1)  # +1 for MIDI compatibility
	return :($total)
end

# Navigate letter names
function letter_step(::Type{L}, steps::Int) where {L <: LetterName}
	letters = [C, D, E, F, G, A, B]
	current = letter_position(L)
	new_pos = mod(current + steps, 7)
	new_letter = letters[new_pos + 1]
	return new_letter
end

