
abstract type LetterName end
struct C <: LetterName end
struct D <: LetterName end
struct E <: LetterName end
struct F <: LetterName end
struct G <: LetterName end
struct A <: LetterName end
struct B <: LetterName end

struct Accidental{Int} end
Accidental(n::Int) = Accidental{n}
offset(::Type{Accidental{N}}) where N = N

const Natural = Accidental(0)
const Sharp = Accidental(1)
const Flat = Accidental(-1)
const DoubleSharp = Accidental(2)
const DoubleFlat = Accidental(-2)

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
const C𝄫 = PitchClass(C, DoubleFlat)
const D𝄫 = PitchClass(D, DoubleFlat)
const E𝄫 = PitchClass(E, DoubleFlat)
const F𝄫 = PitchClass(F, DoubleFlat)
const G𝄫 = PitchClass(G, DoubleFlat)
const A𝄫 = PitchClass(A, DoubleFlat)
const B𝄫 = PitchClass(B, DoubleFlat)
const C𝄪 = PitchClass(C, DoubleSharp)
const D𝄪 = PitchClass(D, DoubleSharp)
const E𝄪 = PitchClass(E, DoubleSharp)
const F𝄪 = PitchClass(F, DoubleSharp)
const G𝄪 = PitchClass(G, DoubleSharp)
const A𝄪 = PitchClass(A, DoubleSharp)
const B𝄪 = PitchClass(B, DoubleSharp)

letter(::Type{PitchClass{L, A}}) where {L, A} = L
accidental(::Type{PitchClass{L, A}}) where {L, A} = A
register(::Type{PitchClass{L, A}}) where {L, A} = nothing
pitch_class(::Type{PitchClass{L, A}}) where {L, A} = PitchClass(L, A)

letter(::Type{Pitch{PC, Register}}) where {PC, Register} = letter(PC)
accidental(::Type{Pitch{PC, Register}}) where {PC, Register} = accidental(PC)
register(::Type{Pitch{PC, Register}}) where {PC, Register} = Register
pitch_class(::Type{Pitch{PC, Register}}) where {PC, Register} = PC

GenericPitchClass(::Type{PC}) where PC <: PitchClass = PitchClass(letter(PC))
const GPC = GenericPitchClass

