
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
offset(::Type{Interval{N, Minor}}) where N = N in [2, 3, 6, 7] ? -1 : error("Invalid interval specification")
offset(::Type{Interval{N, Diminished}}) where N = N in [2, 3, 6, 7] ? -2 : -1
offset(::Type{Interval{N, Major}}) where N = N in [2, 3, 6, 7] ? 0 :  error("Invalid interval specification")
offset(::Type{Interval{N, Perfect}}) where N = N in [1, 4, 5, 8] ? 0 :  error("Invalid interval specification")
offset(::Type{Interval{N, Augmented}}) where N = 1

function semitones(interval::Type{Interval{N, Quality}}) where {N, Quality}
	simple_n = (N - 1) % 7 + 1 # 1-based (1=unison, 8=octave)
	octaves = (N - 1) ÷ 7
	simple_semitones = base(Interval{simple_n, Quality}) + offset(Interval{simple_n, Quality})
	return simple_semitones + 12 * octaves
end


## operator overloads for interval arithmetic

function Base.:+(::Type{L}, ::Type{GenericInterval{N}}) where {L <: LetterName, N}
	return move(LetterSpace, L, N)
end

# todo: should this return a PC? maybe this op does not really make sense; reconsider
function Base.:+(::Type{PC}, ::Type{GenericInterval{N}}) where {PC <: PitchClass, N}
	return move(LetterSpace, letter(PC), N)
end

# todo: should it be move's responsibility to spell correctly?

# for intervals 2, 3, 6, 7 (i.e. where major and minor qualities exist), 
# minor denotes -1, diminished -2, and augmented +1, relative to major;
# for intervals 1, 4, 5, 8 (i.e. ones where perfect quality exists),
# diminished denotes - 1, augmenting denotes + 1
# (note that MusicTheory.jl is incorrect re: diminished seconds)

function Base.:+(::Type{PC}, ::Type{Interval{N, Quality}}) where {PC <: PitchClass, N, Quality}
	return move(PitchClassSpace, PC, semitones(Interval{N, Quality}))
end





