
abstract type MusicalSpace end
abstract type GenericSpace <: MusicalSpace end # operates on LetterNames (i.e. unsigned)
abstract type SignedSpace <: MusicalSpace end  # operates on PitchClasses (i.e. chromatic)

# trait to distinguish between circular and linear spaces
abstract type TopologyStyle end
abstract type Linear <: TopologyStyle end
abstract type Circular <: TopologyStyle end

abstract type Direction end

abstract type LinearDirection end
struct Left <: LinearDirection end
struct Right <: LinearDirection end

abstract type CircularDirection end
struct Clockwise <: CircularDirection end
struct Counterclockwise <: CircularDirection end

function distance(
		::Type{MS}, ::Type{T1}, ::Type{T2}
	) where {MS <: MusicalSpace, T1 <: Union{LetterName, PitchClass}, T2 <: Union{LetterName, PitchClass}}
	return distance(MS, TopologyStyle(MS), T1, T2)
end

# distance on the number line
function distance(
		::Type{MS}, ::Type{Linear}, ::Type{T1}, ::Type{T2}
	) where {MS <: MusicalSpace, T1 <: Union{LetterName, PitchClass}, T2 <: Union{LetterName, PitchClass}}
	return abs(number(MS, T2) - number(MS, T1))
end

# distance on a circular topology (the lesser of clockwise, counterclockwise distance)
function distance(
		::Type{MS}, ::Type{Circular}, ::Type{T1}, ::Type{T2}
	) where {MS <: MusicalSpace, T1 <: Union{LetterName, PitchClass}, T2 <: Union{LetterName, PitchClass}}
	clockwise_dist = mod(number(MS, T2) - number(MS, T1), size(MS))
	counterclockwise_dist = size(MS) - clockwise_dist
	return min(clockwise_dist, counterclockwise_dist)
end

function direction(
		::Type{MS}, ::Type{PC1}, ::Type{PC2}
	) where {MS <: MusicalSpace, PC1, PC2}
	return direction(MS, TopologyStyle(MS), PC1, PC2)
end

# direction on the number line (Left or Right)
function direction(
		::Type{MS}, ::Type{Linear}, ::Type{PC1}, ::Type{PC2}
	) where {MS <: MusicalSpace, PC1, PC2}
	return number(MS, PC1) > number(MS, PC2) ? Left : Right
end

# direction on a circular topology (Clockwise or Counterclockwise)
function direction(
		::Type{MS}, ::Type{Circular}, ::Type{T1}, ::Type{T2}
	) where {MS <: MusicalSpace, T1, T2}
	pos1 = number(MS, T1)
	pos2 = number(MS, T2)
	forward_dist = mod(pos2 - pos1, size(MS))
	backward_dist = mod(pos1 - pos2, size(MS))
	return forward_dist <= backward_dist ? Clockwise : Counterclockwise
end

struct LetterSpace <: GenericSpace end
Base.IteratorSize(::Type{<:LetterSpace}) = Base.HasLength()
Base.isfinite(::Type{LetterSpace}) = true
Base.size(::Type{LetterSpace}) = 7
TopologyStyle(::Type{LetterSpace}) = Circular
LetterName(::Type{LetterSpace}, n::Integer) = LetterName(LetterSpace, Val(mod(n, 7)))
LetterName(::Type{LetterSpace}, ::Val{0}) = C
LetterName(::Type{LetterSpace}, ::Val{1}) = D
LetterName(::Type{LetterSpace}, ::Val{2}) = E
LetterName(::Type{LetterSpace}, ::Val{3}) = F
LetterName(::Type{LetterSpace}, ::Val{4}) = G
LetterName(::Type{LetterSpace}, ::Val{5}) = A
LetterName(::Type{LetterSpace}, ::Val{6}) = B
number(::Type{LetterSpace}, ::Type{PC}) where PC <: PitchClass = number(LetterSpace, GPC(PC))
number(::Type{LetterSpace}, ::Type{C}) = 0
number(::Type{LetterSpace}, ::Type{D}) = 1
number(::Type{LetterSpace}, ::Type{E}) = 2
number(::Type{LetterSpace}, ::Type{F}) = 3
number(::Type{LetterSpace}, ::Type{G}) = 4
number(::Type{LetterSpace}, ::Type{A}) = 5
number(::Type{LetterSpace}, ::Type{B}) = 6

# todo: allow enharmonic equivalents
struct PitchClassSpace <: SignedSpace end
Base.IteratorSize(::Type{<:PitchClassSpace}) = Base.HasLength()
Base.isfinite(::Type{PitchClassSpace}) = true
Base.size(::Type{PitchClassSpace}) = 12
TopologyStyle(::Type{PitchClassSpace}) = Circular
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

struct LineOfFifths <: SignedSpace end
Base.IteratorSize(::Type{<:LineOfFifths}) = Base.IsInfinite()
Base.isfinite(::Type{LineOfFifths}) = false
Base.size(::Type{LineOfFifths}) = error("Base.size not implemented for infinite spaces")
TopologyStyle(::Type{LineOfFifths}) = Linear
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

function move(::Type{MS}, ::Type{L}, steps::Int) where {MS <: GenericSpace, L <: LetterName}
	return move(MS, TopologyStyle(MS), L, steps)
end

function move(::Type{MS}, ::Type{PC}, steps::Int) where {MS <: SignedSpace, PC <: PitchClass}
	return move(MS, TopologyStyle(MS), PC, steps)
end

function move(::Type{MS}, ::Type{Circular}, ::Type{L}, steps::Int) where {MS <: GenericSpace, L}
	new_pos = mod(number(MS, L) + steps, size(MS))
	return LetterName(MS, new_pos)
end

function move(::Type{MS}, ::Type{Linear}, ::Type{L}, steps::Int) where {MS <: GenericSpace, L}
	new_pos = number(MS, L) + steps
	return LetterName(MS, new_pos)
end

function move(::Type{MS}, ::Type{Circular}, ::Type{PC}, steps::Int) where {MS <: SignedSpace, PC}
	new_pos = mod(number(MS, PC) + steps, size(MS))
	return PitchClass(MS, new_pos)
end

function move(::Type{MS}, ::Type{Linear}, ::Type{PC}, steps::Int) where {MS <: SignedSpace, PC}
	new_pos = number(MS, PC) + steps
	return PitchClass(MS, new_pos)
end







