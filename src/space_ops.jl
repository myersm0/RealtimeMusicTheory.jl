
## distance

# user-facing distance function; will dispatch appropriate specific function based on traits
function distance(
		::Type{MS}, ::Type{T1}, ::Type{T2}
	) where {MS <: MusicalSpace, T1 <: Union{LetterName, PitchClass}, T2 <: Union{LetterName, PitchClass}}
	return distance(MS, TopologyStyle(MS), T1, T2)
end

# distance on the number line for linear spaces
function distance(
		::Type{MS}, ::Type{Linear}, ::Type{T1}, ::Type{T2}
	) where {MS <: MusicalSpace, T1 <: Union{LetterName, PitchClass}, T2 <: Union{LetterName, PitchClass}}
	return abs(number(MS, T2) - number(MS, T1))
end

# distance on a circular topology (the lesser of clockwise, counterclockwise distance)
function distance(
		::Type{MS}, ::Type{Circular}, ::Type{T1}, ::Type{T2}
	) where {MS <: MusicalSpace, T1 <: Union{LetterName, PitchClass}, T2 <: Union{LetterName, PitchClass}}
	clockwise_dist = mod(number(MS, T2) - number(MS, T1), length(MS))
	counterclockwise_dist = size(MS) - clockwise_dist
	return min(clockwise_dist, counterclockwise_dist)
end


## direction

# user-facing direction function; will dispatch appropriate specific function based on traits
function direction(
		::Type{MS}, ::Type{PC1}, ::Type{PC2}
	) where {MS <: MusicalSpace, PC1, PC2}
	return direction(MS, TopologyStyle(MS), PC1, PC2)
end

# direction on the number line (Left or Right) for linear spaces
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



## enharmonic functions

is_enharmonic(::Type{PC1}, ::Type{PC2}) where {PC1 <: PitchClass, PC2 <: PitchClass} = 
	mod(distance(LineOfFifths, PC1, PC2), 12) == 0

find_enharmonics(::Type{PC}, n::Int) where {PC1 <: PitchClass} = 
	find_enharmonics(PC, D♮, n)

# given a reference pitch class PC2, find the `n` enharmonic equivalents of `PC1`
# that are closest in LineOfFifths space to PC2.
function find_enharmonics(::Type{PC1}, ::Type{PC2}, n::Int) where {PC1 <: PitchClass, PC2 <: PitchClass}
	start = number(LineOfFifths, PC1)
	reference = number(LineOfFifths, PC2)
	k = round(Int, -start / 12)
	m = start + 12 * k
	radius = n * 12
	rng = sort(m .+ -radius:12:radius, by = x -> abs(x - reference))
	return (PitchClass(LineOfFifths, i) for i in Iterators.take(rng, n))
end



## movement in a space

function move(::Type{MS}, ::Type{T}, steps::Integer) where {MS <: MusicalSpace, T}
	# todo: sanity check the type T
	return move(MS, TopologyStyle(MS), T, steps)
end

function move(::Type{MS}, ::Type{Circular}, ::Type{T}, steps::Integer) where {MS <: MusicalSpace, T}
	new_pos = mod(number(MS, T) + steps, size(MS))
	return eltype(MS)(MS, new_pos)
end

function move(::Type{MS}, ::Type{Linear}, ::Type{T}, steps::Integer) where {MS <: MusicalSpace, T}
	new_pos = number(MS, L) + steps
	return eltype(MS)(MS, new_pos)
end


## indexing into a space

function Base.getindex(::Type{S}, i::Int) where S <: MusicalSpace
	return eltype(S)(S, i)
end

function Base.getindex(::Type{S}, ::Type{T}, length::Int) where {S <: MusicalSpace, T}
	from = number(S, T)
	to = from + length - 1
	return (eltype(S)(S, i) for i in from:to)
end

function Base.getindex(::Type{S}, ::Type{T1}, ::Type{T2}) where {S <: MusicalSpace, T1, T2}
	from = number(S, T1)
	to = number(S, T2)
	step = from < to ? 1 : -1
	return (eltype(S)(S, i) for i in from:step:to)
end

# Make SpaceExpr a proper parametric type
struct SpaceExpr{Op, Arg1, Arg2} end

# Ensure arithmetic returns the right type structure
Base.:+(::Type{PC}, n::Int) where {PC <: PitchClass} = SpaceExpr{:+, PC, Val{n}}
Base.:-(::Type{PC}, n::Int) where {PC <: PitchClass} = SpaceExpr{:-, PC, Val{n}}

function evaluate_in_space(::Type{S}, ::Type{SpaceExpr{Op, PC, Val{N}}}) where {S <: MusicalSpace, Op, PC, N}
	base_pos = number(S, PC)
	return Op == :+ ? base_pos + N : base_pos - N
end

evaluate_in_space(::Type{S}, ::Type{PC}) where {S <: MusicalSpace, PC <: PitchClass} = number(S, PC)
evaluate_in_space(::Type{S}, n::Int) where {S <: MusicalSpace} = n

# three-argument getindex with required step
function Base.getindex(::Type{S}, from_expr, step::Int, to_expr) where {S <: MusicalSpace}
	from = evaluate_in_space(S, from_expr)
	to = evaluate_in_space(S, to_expr)
	if step > 0
		from <= to ? (eltype(S)(S, i) for i in from:step:to) : 
		            (eltype(S)(S, i) for i in from:step:(to + length(S)))  # wrap around
	else
		from >= to ? (eltype(S)(S, i) for i in from:step:to) :
		            (eltype(S)(S, i) for i in from:step:(to - length(S)))  # wrap around
	end
end

# Two-part colon (default step 1)
struct RangeSpec{From, To} end
Base.:(:)(::Type{From}, ::Type{To}) where {From, To} = RangeSpec{From, To}

# Three-part colon with explicit step
struct StepRangeSpec{From, Step, To} end
Base.:(:)(::Type{RangeSpec{From, To}}, step::Int) where {From, To} = StepRangeSpec{From, Val{step}, To}

# Handle both in getindex
function Base.getindex(::Type{S}, ::Type{RangeSpec{From, To}}) where {S <: MusicalSpace, From, To}
    # Default step = 1
    from = evaluate_in_space(S, From)
    to = evaluate_in_space(S, To)
    return (eltype(S)(S, i) for i in from:1:to)
end

function Base.getindex(::Type{S}, ::Type{StepRangeSpec{From, Val{Step}, To}}) where {S <: MusicalSpace, From, Step, To}
    from = evaluate_in_space(S, From)
    to = evaluate_in_space(S, To)
    return (eltype(S)(S, i) for i in from:Step:to)
end

# allows e.g. `sort(collect(LineOfFifths[G♮-1:G♮+5]), by = PitchClassSpace)`
(::Type{S})(x) where {S <: MusicalSpace} = number(S, x)
(::Type{S})(x::Number) where {S <: MusicalSpace} = eltype(S)(S, x)








