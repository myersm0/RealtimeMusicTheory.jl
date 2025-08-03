
abstract type MusicalSpace end

distance(::Type{MS}, ::Type{PC1}, ::Type{PC2}) where {MS <: MusicalSpace, PC1 <: PitchClass, PC2 <: PitchClass} = 
	abs(number(MS, PC2) - number(MS, PC1))

struct LetterSpace <: MusicalSpace end
LetterName(::Type{LetterSpace}, n::Integer) = LetterName(LetterSpace, Val(n))
LetterName(::Type{LetterSpace}, ::Val{0}) = C
LetterName(::Type{LetterSpace}, ::Val{1}) = D
LetterName(::Type{LetterSpace}, ::Val{2}) = E
LetterName(::Type{LetterSpace}, ::Val{3}) = F
LetterName(::Type{LetterSpace}, ::Val{4}) = G
LetterName(::Type{LetterSpace}, ::Val{5}) = A
LetterName(::Type{LetterSpace}, ::Val{6}) = B
number(::Type{LetterSpace}, ::Type{PC}) where PC <: PitchClass = number(LetterSpace, PitchClass(letter(PC)))
number(::Type{LetterSpace}, ::Type{C♮}) = 0
number(::Type{LetterSpace}, ::Type{D♮}) = 1
number(::Type{LetterSpace}, ::Type{E♮}) = 2
number(::Type{LetterSpace}, ::Type{F♮}) = 3
number(::Type{LetterSpace}, ::Type{G♮}) = 4
number(::Type{LetterSpace}, ::Type{A♮}) = 5
number(::Type{LetterSpace}, ::Type{B♮}) = 6

struct PitchClassSpace <: MusicalSpace end
PitchClass(n::Int) = PitchClass(PitchClassSpace, Val(n))
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
number(::Type{PC}) where PC <: PitchClass = number(PitchClassSpace, PC)
number(::Type{PitchClassSpace}, ::Type{C♮}) = 0
number(::Type{PitchClassSpace}, ::Type{C♯}) = 1
number(::Type{PitchClassSpace}, ::Type{D♮}) = 2
number(::Type{PitchClassSpace}, ::Type{D♯}) = 3
number(::Type{PitchClassSpace}, ::Type{E♮}) = 4
number(::Type{PitchClassSpace}, ::Type{F♮}) = 5
number(::Type{PitchClassSpace}, ::Type{F♯}) = 6
number(::Type{PitchClassSpace}, ::Type{G♮}) = 7
number(::Type{PitchClassSpace}, ::Type{G♯}) = 7
number(::Type{PitchClassSpace}, ::Type{A♮}) = 9
number(::Type{PitchClassSpace}, ::Type{A♯}) = 10
number(::Type{PitchClassSpace}, ::Type{B♮}) = 11


struct LineOfFifths <: MusicalSpace end
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

is_enharmonic(::Type{PC1}, ::Type{PC2}) where {PC1 <: PitchClass, PC2 <: PitchClass} = 
	distance(LineOfFifths, PC1, PC2) == 12



















