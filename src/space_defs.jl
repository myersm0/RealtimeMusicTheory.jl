
abstract type MusicalSpace end
abstract type DiscreteSpace <: MusicalSpace end
abstract type ContinuousSpace <: MusicalSpace end # not implemented but defined for extensibility

Base.eltype(::Type{S}) where S <: DiscreteSpace = eltype(SpellingStyle(S), RegisterStyle(S))
Base.eltype(::Type{<:GenericSpelling}, ::Any) = LetterName
Base.eltype(::Type{<:SpecificSpelling}, ::Type{ClassLevel}) = PitchClass
Base.eltype(::Type{<:SpecificSpelling}, ::Type{Registral}) = Pitch

"""
    LetterSpace

A circular space containing the 7 letter names (C, D, E, F, G, A, B) in that order.
"""
struct LetterSpace <: DiscreteSpace end
TopologyStyle(::Type{LetterSpace}) = Circular
SpellingStyle(::Type{LetterSpace}) = GenericSpelling
RegisterStyle(::Type{LetterSpace}) = ClassLevel
Base.IteratorSize(::Type{<:LetterSpace}) = Base.HasLength()
Base.isfinite(::Type{LetterSpace}) = true
Base.size(::Type{LetterSpace}) = 7
Base.length(::Type{LetterSpace}) = 7
LetterName(::Type{LetterSpace}, n::Integer) = LetterName(LetterSpace, Val(mod(n, 7)))
LetterName(::Type{LetterSpace}, ::Val{0}) = C
LetterName(::Type{LetterSpace}, ::Val{1}) = D
LetterName(::Type{LetterSpace}, ::Val{2}) = E
LetterName(::Type{LetterSpace}, ::Val{3}) = F
LetterName(::Type{LetterSpace}, ::Val{4}) = G
LetterName(::Type{LetterSpace}, ::Val{5}) = A
LetterName(::Type{LetterSpace}, ::Val{6}) = B
number(::Type{LetterSpace}, ::Type{PC}) where PC <: PitchClass = number(LetterSpace, letter(PC))
number(::Type{LetterSpace}, ::Type{C}) = 0
number(::Type{LetterSpace}, ::Type{D}) = 1
number(::Type{LetterSpace}, ::Type{E}) = 2
number(::Type{LetterSpace}, ::Type{F}) = 3
number(::Type{LetterSpace}, ::Type{G}) = 4
number(::Type{LetterSpace}, ::Type{A}) = 5
number(::Type{LetterSpace}, ::Type{B}) = 6

"""
    GenericFifthsSpace

A circular space containing the 7 letter names arranged by perfect fifths.
"""
struct GenericFifthsSpace <: DiscreteSpace end
TopologyStyle(::Type{GenericFifthsSpace}) = Circular
SpellingStyle(::Type{GenericFifthsSpace}) = GenericSpelling
RegisterStyle(::Type{GenericFifthsSpace}) = ClassLevel
Base.IteratorSize(::Type{<:GenericFifthsSpace}) = Base.HasLength()
Base.isfinite(::Type{GenericFifthsSpace}) = true
Base.size(::Type{GenericFifthsSpace}) = 7
Base.length(::Type{GenericFifthsSpace}) = 7
LetterName(::Type{GenericFifthsSpace}, n::Integer) = LetterName(GenericFifthsSpace, Val(mod(n, 7)))
LetterName(::Type{GenericFifthsSpace}, ::Val{0}) = C
LetterName(::Type{GenericFifthsSpace}, ::Val{1}) = G
LetterName(::Type{GenericFifthsSpace}, ::Val{2}) = D
LetterName(::Type{GenericFifthsSpace}, ::Val{3}) = A
LetterName(::Type{GenericFifthsSpace}, ::Val{4}) = E
LetterName(::Type{GenericFifthsSpace}, ::Val{5}) = B
LetterName(::Type{GenericFifthsSpace}, ::Val{6}) = F
number(::Type{GenericFifthsSpace}, ::Type{PC}) where PC <: PitchClass = number(GenericFifthsSpace, letter(PC))
number(::Type{GenericFifthsSpace}, ::Type{C}) = 0
number(::Type{GenericFifthsSpace}, ::Type{G}) = 1
number(::Type{GenericFifthsSpace}, ::Type{D}) = 2
number(::Type{GenericFifthsSpace}, ::Type{A}) = 3
number(::Type{GenericFifthsSpace}, ::Type{E}) = 4
number(::Type{GenericFifthsSpace}, ::Type{B}) = 5
number(::Type{GenericFifthsSpace}, ::Type{F}) = 6

"""
    GenericThirdsSpace

A circular space containing the 7 letter names arranged by major thirds.
"""
struct GenericThirdsSpace <: DiscreteSpace end
TopologyStyle(::Type{GenericThirdsSpace}) = Circular
SpellingStyle(::Type{GenericThirdsSpace}) = GenericSpelling
RegisterStyle(::Type{GenericThirdsSpace}) = ClassLevel
Base.IteratorSize(::Type{<:GenericThirdsSpace}) = Base.HasLength()
Base.isfinite(::Type{GenericThirdsSpace}) = true
Base.size(::Type{GenericThirdsSpace}) = 7
Base.length(::Type{GenericThirdsSpace}) = 7
LetterName(::Type{GenericThirdsSpace}, n::Integer) = LetterName(GenericThirdsSpace, Val(mod(n, 7)))
LetterName(::Type{GenericThirdsSpace}, ::Val{0}) = C
LetterName(::Type{GenericThirdsSpace}, ::Val{1}) = E
LetterName(::Type{GenericThirdsSpace}, ::Val{2}) = G
LetterName(::Type{GenericThirdsSpace}, ::Val{3}) = B
LetterName(::Type{GenericThirdsSpace}, ::Val{4}) = D
LetterName(::Type{GenericThirdsSpace}, ::Val{5}) = F
LetterName(::Type{GenericThirdsSpace}, ::Val{6}) = A
number(::Type{GenericThirdsSpace}, ::Type{PC}) where PC <: PitchClass = number(GenericThirdsSpace, letter(PC))
number(::Type{GenericThirdsSpace}, ::Type{C}) = 0
number(::Type{GenericThirdsSpace}, ::Type{E}) = 1
number(::Type{GenericThirdsSpace}, ::Type{G}) = 2
number(::Type{GenericThirdsSpace}, ::Type{B}) = 3
number(::Type{GenericThirdsSpace}, ::Type{D}) = 4
number(::Type{GenericThirdsSpace}, ::Type{F}) = 5
number(::Type{GenericThirdsSpace}, ::Type{A}) = 6

"""
    LineOfFifths

A linear space containing all the pitch classes arranged by perfect fifths.

This is an infinite space centered at D = 0. Spellings get sharper as you proceed from 
zero to the right, or flatter to the left.
"""
struct LineOfFifths <: DiscreteSpace end
TopologyStyle(::Type{LineOfFifths}) = Linear
SpellingStyle(::Type{LineOfFifths}) = SpecificSpelling
RegisterStyle(::Type{LineOfFifths}) = ClassLevel
Base.IteratorSize(::Type{<:LineOfFifths}) = Base.IsInfinite()
Base.isfinite(::Type{LineOfFifths}) = false
Base.size(::Type{LineOfFifths}) = error("Base.size not implemented for infinite spaces")
Base.length(::Type{LineOfFifths}) = error("Base.length not implemented for infinite spaces")
PitchClass(::Type{LineOfFifths}, n::Integer) = PitchClass(LineOfFifths, Val(n))
PitchClass(::Type{LineOfFifths}, ::Val{-3}) = F♮
PitchClass(::Type{LineOfFifths}, ::Val{-2}) = C♮
PitchClass(::Type{LineOfFifths}, ::Val{-1}) = G♮
PitchClass(::Type{LineOfFifths}, ::Val{0}) = D♮
PitchClass(::Type{LineOfFifths}, ::Val{1}) = A♮
PitchClass(::Type{LineOfFifths}, ::Val{2}) = E♮
PitchClass(::Type{LineOfFifths}, ::Val{3}) = B♮
@generated function PitchClass(::Type{LineOfFifths}, ::Val{N}) where {N}
	base_position = mod(N, 7)
	base_position > 3 && (base_position -= 7)
	accidental_offset = (N - base_position) ÷ 7
	return quote
		base_pc = PitchClass(LineOfFifths, Val($base_position))
		PitchClass(letter(base_pc), Accidental($accidental_offset))
	end
end
number(::Type{LineOfFifths}, n::Integer) = PitchClass(LineOfFifths, Val(n))
number(::Type{LineOfFifths}, ::Type{F♮}) = -3
number(::Type{LineOfFifths}, ::Type{C♮}) = -2
number(::Type{LineOfFifths}, ::Type{G♮}) = -1
number(::Type{LineOfFifths}, ::Type{D♮}) = 0
number(::Type{LineOfFifths}, ::Type{A♮}) = 1
number(::Type{LineOfFifths}, ::Type{E♮}) = 2
number(::Type{LineOfFifths}, ::Type{B♮}) = 3
number(::Type{LineOfFifths}, ::Type{PC}) where PC <: PitchClass = 
	number(LineOfFifths, GPC(PC)) + offset(accidental(PC)) * 7

"""
    CircleOfFifths

A circular space containing the 12 pitch classes (without enharmonic distinction)
arranged by perfect fifths.

The standard circle: C, G, D, A, E, B, F♯, C♯, G♯, D♯, A♯, F.
"""
struct CircleOfFifths <: DiscreteSpace end
TopologyStyle(::Type{CircleOfFifths}) = Circular
SpellingStyle(::Type{CircleOfFifths}) = SpecificSpelling
RegisterStyle(::Type{CircleOfFifths}) = ClassLevel
Base.IteratorSize(::Type{<:CircleOfFifths}) = Base.HasLength()
Base.isfinite(::Type{CircleOfFifths}) = true
Base.size(::Type{CircleOfFifths}) = 12
Base.length(::Type{CircleOfFifths}) = 12
PitchClass(::Type{CircleOfFifths}, n::Integer) = PitchClass(CircleOfFifths, Val(n))
PitchClass(::Type{CircleOfFifths}, ::Val{0}) = C♮
PitchClass(::Type{CircleOfFifths}, ::Val{1}) = G♮
PitchClass(::Type{CircleOfFifths}, ::Val{2}) = D♮
PitchClass(::Type{CircleOfFifths}, ::Val{3}) = A♮
PitchClass(::Type{CircleOfFifths}, ::Val{4}) = E♮
PitchClass(::Type{CircleOfFifths}, ::Val{5}) = B♮
PitchClass(::Type{CircleOfFifths}, ::Val{6}) = F♯
PitchClass(::Type{CircleOfFifths}, ::Val{7}) = C♯
PitchClass(::Type{CircleOfFifths}, ::Val{8}) = G♯
PitchClass(::Type{CircleOfFifths}, ::Val{9}) = D♯
PitchClass(::Type{CircleOfFifths}, ::Val{10}) = A♯
PitchClass(::Type{CircleOfFifths}, ::Val{11}) = F♮
number(::Type{CircleOfFifths}, ::Type{C♮}) = 0
number(::Type{CircleOfFifths}, ::Type{G♮}) = 1
number(::Type{CircleOfFifths}, ::Type{D♮}) = 2
number(::Type{CircleOfFifths}, ::Type{A♮}) = 3
number(::Type{CircleOfFifths}, ::Type{E♮}) = 4
number(::Type{CircleOfFifths}, ::Type{B♮}) = 5
number(::Type{CircleOfFifths}, ::Type{F♯}) = 6
number(::Type{CircleOfFifths}, ::Type{C♯}) = 7
number(::Type{CircleOfFifths}, ::Type{G♯}) = 8
number(::Type{CircleOfFifths}, ::Type{D♯}) = 9
number(::Type{CircleOfFifths}, ::Type{A♯}) = 10
number(::Type{CircleOfFifths}, ::Type{F♮}) = 11

"""
    PitchClassSpace

A circular chromatic space containing 12 pitch classes arranged by semitones,
without enharmonic distinctions.

The standard chromatic scale: C, C♯, D, D♯, E, F, F♯, G, G♯, A, A♯, B.
"""
struct PitchClassSpace <: DiscreteSpace end
TopologyStyle(::Type{PitchClassSpace}) = Circular
SpellingStyle(::Type{PitchClassSpace}) = SpecificSpelling
RegisterStyle(::Type{PitchClassSpace}) = ClassLevel
Base.IteratorSize(::Type{<:PitchClassSpace}) = Base.HasLength()
Base.isfinite(::Type{PitchClassSpace}) = true
Base.size(::Type{PitchClassSpace}) = 12
Base.length(::Type{PitchClassSpace}) = 12
PitchClass(n::Integer) = PitchClass(PitchClassSpace, Val(n))
PitchClass(::Type{PitchClassSpace}, n::Integer) = PitchClass(PitchClassSpace, Val(n))
PitchClass(::Type{PitchClassSpace}, ::Val{0}) = C♮
PitchClass(::Type{PitchClassSpace}, ::Val{1}) = C♯
PitchClass(::Type{PitchClassSpace}, ::Val{2}) = D♮
PitchClass(::Type{PitchClassSpace}, ::Val{3}) = D♯
PitchClass(::Type{PitchClassSpace}, ::Val{4}) = E♮
PitchClass(::Type{PitchClassSpace}, ::Val{5}) = F♮
PitchClass(::Type{PitchClassSpace}, ::Val{6}) = F♯
PitchClass(::Type{PitchClassSpace}, ::Val{7}) = G♮
PitchClass(::Type{PitchClassSpace}, ::Val{8}) = G♯
PitchClass(::Type{PitchClassSpace}, ::Val{9}) = A♮
PitchClass(::Type{PitchClassSpace}, ::Val{10}) = A♯
PitchClass(::Type{PitchClassSpace}, ::Val{11}) = B♮
number(::Type{PitchClassSpace}, ::Type{C♮}) = 0
number(::Type{PitchClassSpace}, ::Type{C♯}) = 1
number(::Type{PitchClassSpace}, ::Type{D♮}) = 2
number(::Type{PitchClassSpace}, ::Type{D♯}) = 3
number(::Type{PitchClassSpace}, ::Type{E♮}) = 4
number(::Type{PitchClassSpace}, ::Type{F♮}) = 5
number(::Type{PitchClassSpace}, ::Type{F♯}) = 6
number(::Type{PitchClassSpace}, ::Type{G♮}) = 7
number(::Type{PitchClassSpace}, ::Type{G♯}) = 8
number(::Type{PitchClassSpace}, ::Type{A♮}) = 9
number(::Type{PitchClassSpace}, ::Type{A♯}) = 10
number(::Type{PitchClassSpace}, ::Type{B♮}) = 11

"""
    DiscretePitchSpace

An infinite linear space of chromatic pitches arranged by semitones,
without enharmonic distinctions.

Numbers in this space correspond to MIDI numbers, at least within the octave range
of -1 to 8 (MIDI numbers 0 to 119); but it also extends infinitely in both directions.
Middle C (C4) = 60.
"""
struct DiscretePitchSpace <: DiscreteSpace end
TopologyStyle(::Type{DiscretePitchSpace}) = Linear
SpellingStyle(::Type{DiscretePitchSpace}) = SpecificSpelling
RegisterStyle(::Type{DiscretePitchSpace}) = Registral
Base.IteratorSize(::Type{<:DiscretePitchSpace}) = Base.IsInfinite()
Base.isfinite(::Type{DiscretePitchSpace}) = false
Pitch(n::Integer) = Pitch(DiscretePitchSpace, Val(n))
Pitch(::Type{DiscretePitchSpace}, n::Integer) = Pitch(DiscretePitchSpace, Val(n))
function Pitch(::Type{DiscretePitchSpace}, ::Val{N}) where N
	pc_num = N % 12
	register = (N ÷ 12) - 1
	return Pitch(PitchClass(PitchClassSpace, Val(pc_num)), register)
end
function number(::Type{DiscretePitchSpace}, ::Type{Pitch{PC, Reg}}) where {PC, Reg}
	# note that this function def has been modified from the former, simpler:
	# `12 * (Reg + 1) + number(PC)` in order to handle edge cases 
	# where an accidental(s) pushes the pitch into the next register
	return 12 * (Reg + 1) + number(GPC(PC)) + offset(accidental(PC))
end


# generic prototype
function number(::Type{P}) where P <: PitchRepresentation end

# default number() functions for convenience where no space is specified:
number(::Type{L}) where L <: LetterName = number(LetterSpace, L)
number(::Type{PC}) where PC <: PitchClass = number(PitchClassSpace, PC)
number(::Type{P}) where P <: Pitch = number(DiscretePitchSpace, P)

# if supplied PitchClass is not defined above, need to find an enharmonic equivalent
# as follows and then dispatch to that instead:
@generated function number(::Type{S}, ::Type{PC}) where {S <: DiscreteSpace, PC <: PitchClass}
	current_pos = number(LineOfFifths, PC)
	acc_offset = offset(accidental(PC))
	# force it to have a canonical pos in PitchClassSpace i.e. between -3 and 8:
	canonical_pos = mod(current_pos + 3, 12) - 3
	canonical_pc = PitchClass(LineOfFifths, canonical_pos)
	return :(number(S, $canonical_pc))
end


