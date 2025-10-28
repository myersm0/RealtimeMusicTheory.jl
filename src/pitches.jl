
abstract type PitchRepresentation end

abstract type LetterName <: PitchRepresentation end
struct C <: LetterName end
struct D <: LetterName end
struct E <: LetterName end
struct F <: LetterName end
struct G <: LetterName end
struct A <: LetterName end
struct B <: LetterName end

struct Accidental{Int} end

"""
    Accidental(n)

Specify an accidental where `n` is the number of flats (if n < 0) or sharps (if n > 0).
"""
Accidental(n::Integer) = Accidental{Int(n)}

offset(::Type{Accidental{N}}) where N = N

const ♮ = const Natural = Accidental(0)
const ♯ = const Sharp = Accidental(1)
const ♭ = const Flat = Accidental(-1)
const 𝄪 = const DoubleSharp = Accidental(2)
const 𝄫 = const DoubleFlat = Accidental(-2)

struct PitchClass{L <: LetterName, A <: Accidental} <: PitchRepresentation end
struct Pitch{PC <: PitchClass, Register} <: PitchRepresentation end

"""
    PitchClass(L)

Construct a PitchClass with LetterName `L` and a natural accidental sign.
"""
PitchClass(::Type{L}) where {L <: LetterName} = 
	PitchClass{L, Natural}

"""
    PitchClass(L, A)

Construct a PitchClass with LetterName `L` and Accidental `A`.
"""
PitchClass(::Type{L}, ::Type{A}) where {L <: LetterName, A <: Accidental} = 
	PitchClass{L, A}

# todo: remove this ctor, could be confusing
PitchClass(::Type{L}, n::Integer) where L <: LetterName = 
	PitchClass{L, Accidental(n)}

"""
    Pitch(PC, R)
Construct a Pitch from PitchClass `PC` and register number `R`.

Register number should be between -1 and 8 if you want MIDI-number compliance
(i.e. pitches numbered from 0 to 119), but no hard limit in either direction is imposed.
"""
Pitch(::Type{PC}, register::Integer) where {PC <: PitchClass} = 
	Pitch{PC, Int(register)}

"""
    Pitch(L, A, R)
Construct a Pitch from letter name `L`, accidental `A` (default: `Natural`), and register number `R`.

Register number should be between -1 and 8 if you want MIDI-number compliance
(i.e. pitches numbered from 0 to 119), but no hard limit in either direction is imposed.
"""
Pitch(::Type{L}, ::Type{A}, register::Integer) where {L <: LetterName, A <: Accidental} = 
	Pitch{PitchClass{L, A}, Int(register)}

Pitch(::Type{L}, register::Integer) where {L <: LetterName} = 
	Pitch{PitchClass{L, Natural}, Int(register)}

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

"""
	 letter(PR)

Get the LetterName of a `PitchRepresentation`.
"""
function letter(::Type{PitchRepresentation}) end

"""
	 accidental(PR)

Get the Accidental of a `PitchRepresentation`.
"""
function accidental(::Type{PitchRepresentation}) end

"""
	 register(PR)

Get the register number of a `PitchRepresentation`, or `nothing` if it's not defined.

This only makes sense for `Pitch` and for any other types (none yet implemented)
that encode register information, i.e. for which `SpellingStyle(T) == Registral`.
"""
function register(::Type{PitchRepresentation}) end

"""
	 pitch_class(PR)

Get the PitchClass of a `PitchRepresentation`, or `nothing` if it's not defined.

This only makes sense for PitchRepresentation types that contain accidental spellings,
i.e. types `T` for which `SpellingStyle(T) == SpecificSpelling`.
"""
function pitch_class(::Type{PitchRepresentation}) end

letter(::Type{L}) where L <: LetterName = L
accidental(::Type{L}) where L <: LetterName = nothing
register(::Type{L}) where L <: LetterName = nothing
pitch_class(::Type{L}) where L <: LetterName = nothing

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

# todo: the default of n = 1 is not appropriate for this one
# todo: should be able to modify pitches like this as well
"""
	 modify(PC)

Sharpen or flatten a PitchClass `PC` by `n` semitones.
"""
modify(::Type{PitchClass{L, A}}, n::Integer = 1) where {L, A} = PitchClass(L, offset(A) + n)

"""
	 sharpen(PC, n = 1)

Sharpen PitchClass `PC` by `n` semitones.
"""
sharpen(::Type{PC}, n::Integer = 1) where {PC <: PitchClass} = modify(PC, n)

"""
	 flatten(PC, n = 1)

Flatten PitchClass `PC` by `n` semitones.
"""
flatten(::Type{PC}, n::Integer = 1) where {PC <: PitchClass} = modify(PC, -n)

Base.getindex(::Type{PC}, r::Integer) where PC <: PitchClass = Pitch(PC, r)

