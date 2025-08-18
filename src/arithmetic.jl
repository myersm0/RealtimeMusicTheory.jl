
## helpers

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
offset(::Type{Interval{N, Minor}}) where N      = -1
offset(::Type{Interval{N, Major}}) where N      =  0
offset(::Type{Interval{N, Perfect}}) where N    =  0
offset(::Type{Interval{N, Augmented}}) where N  =  1
offset(::Type{Interval{N, Diminished}}) where N = N in [1, 4, 5, 8] ? -1 : -2

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

