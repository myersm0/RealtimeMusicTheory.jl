
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

# Constructors
PitchClass(::Type{L}, ::Type{A}) where {L <: LetterName, A <: Accidental} = 
	PitchClass{L, A}

PitchClass(::Type{L}) where {L <: LetterName} = 
	PitchClass{L, Natural}

Pitch(::Type{PC}, octave::Int) where {PC <: PitchClass} = 
	Pitch{PC, octave}

Pitch(::Type{L}, ::Type{A}, octave::Int) where {L <: LetterName, A <: Accidental} = 
	Pitch{PitchClass{L, A}, octave}

Pitch(::Type{L}, octave::Int) where {L <: LetterName} = 
	Pitch{PitchClass{L, Natural}, octave}

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

letter(::Type{PitchClass{L, A}}) where {L, A} = L
accidental(::Type{PitchClass{L, A}}) where {L, A} = A
letter(::Type{Pitch{PC, Oct}}) where {PC, Oct} = letter(PC)
accidental(::Type{Pitch{PC, Oct}}) where {PC, Oct} = accidental(PC)
octave(::Type{Pitch{PC, Oct}}) where {PC, Oct} = Oct
pitch_class(::Type{Pitch{PC, Oct}}) where {PC, Oct} = PC

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
	return :(mod($semi, 12))
end

# Total semitones for a pitch (with octave)
@generated function semitone(::Type{Pitch{PC, Oct}}) where {PC, Oct}
	pc_semi = semitone(PC)
	total = pc_semi + 12 * (Oct + 1)  # +1 for MIDI compatibility
	return :($total)
end

# Navigate letter names
function letter_step(::Type{L}, steps::Int) where {L <: LetterName}
	letters = [C, D, E, F, G, A, B]
	current = letter_position(L)
	new_pos = mod(current + steps, 7)
	new_letter = letters[new_pos + 1]
	return :($new_letter)
end

# Add semitones to a pitch class
function add_semitones(::Type{PitchClass{Letter, Acc}}, semitones::Int) where {Letter, Acc}
	current_semi = chromatic_position(Letter) + offset(Acc)
	target_semi = mod(current_semi + semitones, 12)
	# Determine best spelling (prefer sharps when ascending, flats when descending)
	spellings = [
		(0, C, Natural),
		(1, C, Sharp),	# Could also be (D, Flat)
		(2, D, Natural),
		(3, D, Sharp),	# Could also be (E, Flat)
		(4, E, Natural),
		(5, F, Natural),
		(6, F, Sharp),	# Could also be (G, Flat)
		(7, G, Natural),
		(8, G, Sharp),	# Could also be (A, Flat)
		(9, A, Natural),
		(10, A, Sharp),   # Could also be (B, Flat)
		(11, B, Natural)
	]
	# Simple spelling for now - always use sharps
	semi, letter, acc = spellings[target_semi + 1]
	return PitchClass{letter, acc}
end

