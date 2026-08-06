
abstract type IntervalQuality end
struct Perfect <: IntervalQuality end
struct Major <: IntervalQuality end
struct Minor <: IntervalQuality end
struct Augmented <: IntervalQuality end
struct Diminished <: IntervalQuality end

abstract type AbstractInterval end
struct GenericInterval{N} <: AbstractInterval end
struct SpecificInterval{Number, Quality <: IntervalQuality} <: AbstractInterval end

"""
    GenericInterval(n)

Construct a generic interval of size `n` (1-indexed: 1=unison, 2=second, 8=octave, etc.).

Generic intervals represent the letter-name distance without considering accidentals.
"""
GenericInterval(n::Integer) = GenericInterval{Int(n)}

"""
    SpecificInterval(n, Q)

Construct a specific interval with interval number `n` and Quality `Q`.

Valid qualities:
- Perfect: for unison (1), 4th, 5th, and octave (8)
- Major/Minor: for 2nd, 3rd, 6th, 7th
- Augmented/Diminished: for any interval
"""
function SpecificInterval(n::Integer, quality::Type{Q}) where Q <: IntervalQuality
	simple = mod1(n, 7)
	(Q == Perfect && !(simple in [1, 4, 5])) && error("Perfect quality only valid for unison, 4th, 5th, and octave")
	(Q in [Major, Minor] && !(simple in [2, 3, 6, 7])) && error("Major/minor quality only valid for 2nd, 3rd, 6th, 7th")
	return SpecificInterval{Int(n), Q}
end

# note: performance hit when using () instead of {} for these
const Interval = SpecificInterval
const P1 = Interval{1, Perfect}
const m2 = Interval{2, Minor}
const M2 = Interval{2, Major}
const m3 = Interval{3, Minor}
const M3 = Interval{3, Major}
const P4 = Interval{4, Perfect}
const A4 = Interval{4, Augmented}
const d5 = Interval{5, Diminished}
const P5 = Interval{5, Perfect}
const m6 = Interval{6, Minor}
const M6 = Interval{6, Major}
const m7 = Interval{7, Minor}
const M7 = Interval{7, Major}
const P8 = Interval{8, Perfect}


## helpers for interval arithmetic

# base semitones for a major or perfect interval as appropriate
base(::Type{Interval{1, Quality}}) where Quality = 0
base(::Type{Interval{2, Quality}}) where Quality = 2
base(::Type{Interval{3, Quality}}) where Quality = 4
base(::Type{Interval{4, Quality}}) where Quality = 5
base(::Type{Interval{5, Quality}}) where Quality = 7
base(::Type{Interval{6, Quality}}) where Quality = 9
base(::Type{Interval{7, Quality}}) where Quality = 11
base(::Type{Interval{8, Quality}}) where Quality = 12

# how many semitones to shift from interval's base, as a function of quality
# (note: perfect intervals diminish by 1, others by 2)
offset(::Type{Interval{N, Minor}}) where N	  = -1
offset(::Type{Interval{N, Major}}) where N	  =  0
offset(::Type{Interval{N, Perfect}}) where N	=  0
offset(::Type{Interval{N, Augmented}}) where N  =  1
offset(::Type{Interval{N, Diminished}}) where N = N in [1, 4, 5, 8] ? -1 : -2

# position of a pitch in letter space, unrolled across registers
generic_position(::Type{P}) where P <: Pitch = 
	number(LetterSpace, letter(P)) + 7 * register(P)

function semitones(interval::Type{Interval{N, Quality}}) where {N, Quality}
	simple_n = (N - 1) % 7 + 1 # 1-based (1=unison, 8=octave)
	octaves = (N - 1) ÷ 7
	simple_semitones = base(Interval{simple_n, Quality}) + offset(Interval{simple_n, Quality})
	return simple_semitones + 12 * octaves
end


## operator overloads for interval arithmetic

# generic
function Base.:+(::Type{PitchRepresentation}, ::Type{AbstractInterval}) end
function Base.:-(::Type{PitchRepresentation}, ::Type{AbstractInterval}) 
	return error("Subtraction of intervals is not defined")
end

# Letter + GenericInterval
Base.:+(::Type{L}, ::Type{GenericInterval{N}}) where {L <: LetterName, N} = 
	move(LetterSpace, L, N - 1)

# PitchClass + GenericInterval
Base.:+(::Type{PC}, ::Type{GenericInterval{N}}) where {PC <: PitchClass, N} = 
	PitchClass(letter(PC) + GenericInterval{N}, accidental(PC))

# PitchClass + Interval
function Base.:+(::Type{PC}, ::Type{Interval{N, Quality}}) where {PC <: PitchClass, N, Quality}
	simple_target = PitchClass(LineOfFifths, number(LineOfFifths, PC) - 1 + mod(2N - 1, 7))
	modified_target = modify(simple_target, offset(Interval{N, Quality}))
	return modified_target
end

# Pitch + Interval
function Base.:+(::Type{Pitch{PC, Reg}}, ::Type{Interval{N, Quality}}) where {PC, Reg, N, Quality}
	new_pc = PC + Interval{N, Quality}
	octaves = (N - 1) ÷ 7
	# check if we've wrapped in letter space
	old_letter_num = number(LetterSpace, letter(PC))
	new_letter_num = number(LetterSpace, letter(new_pc))
	steps_within = mod(N - 1, 7)
	wrapped = steps_within > 0 && new_letter_num < old_letter_num
	new_register = Reg + octaves + (wrapped ? 1 : 0)
	return Pitch(new_pc, new_register)
end

Base.:^(::Type{I}, n::Integer) where I <: SpecificInterval = 
	[I for _ in 1:n]

# allow adding a vector of intervals to a pitch
Base.:+(::Type{PC}, intervals::Vector) where PC <: PitchClass = 
    foldl(+, intervals; init = PC)

Base.:+(::Type{P}, intervals::Vector) where P <: Pitch = 
    foldl(+, intervals; init = P)


## we can now define an Interval constructor that computes an interval based on given pitches

"""
    Interval(P1, P2)

Compute the specific interval between two pitches.
"""
@generated function Interval(::Type{P1}, ::Type{P2}) where {P1 <: Pitch, P2 <: Pitch}
	steps = generic_position(P2) - generic_position(P1)
	steps < 0 && error("Descending intervals are not supported; got $P1 to $P2")
	number_of_octaves = steps ÷ 7
	simple_number = mod(steps, 7) + 1
	baseline = base(Interval{simple_number, Major}) + 12 * number_of_octaves
	deviation = number(P2) - number(P1) - baseline
	quality = if simple_number in (1, 4, 5)
		deviation ==  0 ? Perfect :
		deviation ==  1 ? Augmented :
		deviation == -1 ? Diminished :
		error("No representable quality for the interval between $P1 and $P2")
	else
		deviation ==  0 ? Major :
		deviation == -1 ? Minor :
		deviation ==  1 ? Augmented :
		deviation == -2 ? Diminished :
		error("No representable quality for the interval between $P1 and $P2")
	end
	return :(Interval{$(steps + 1), $quality})
end





