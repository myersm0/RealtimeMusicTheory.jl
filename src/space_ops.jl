
## distance

"""
    distance(MS, T1, T2)

Calculate the distance between two `PitchRepresentation`s in a `MusicalSpace`.

The distance metric depends on the space's topology:
- Linear spaces: absolute difference in positions
- Circular spaces: the lesser of clockwise and counterclockwise distances
"""
function distance(
		::Type{MS}, ::Type{T1}, ::Type{T2}
		) where {MS <: MusicalSpace, T1 <: PitchRepresentation, T2 <: PitchRepresentation}
	return distance(MS, TopologyStyle(MS), T1, T2)
end

"""
    distance(MS, D, T1, T2)

Calculate the directional distance between two `PitchRepresentation`s in a circular `MusicalSpace`.

Direction `D` can be `Clockwise` or `Counterclockwise`. Only valid for circular spaces.
"""
function distance(
		::Type{MS}, ::Type{D}, ::Type{T1}, ::Type{T2}
		) where {MS <: MusicalSpace, D <: CircularDirection, T1 <: PitchRepresentation, T2 <: PitchRepresentation}
	TopologyStyle(MS) == Circular || error("Directional movement only allowed for Circular spaces.")
	return distance(MS, Circular, D, T1, T2)
end

# distance on the number line for linear spaces
function distance(
		::Type{MS}, ::Type{Linear}, ::Type{T1}, ::Type{T2}
	) where {MS <: MusicalSpace, T1 <: PitchRepresentation, T2 <: PitchRepresentation}
	return abs(number(MS, T2) - number(MS, T1))
end

# distance on a circular topology (the lesser of clockwise, counterclockwise distance)
function distance(
		::Type{MS}, ::Type{Circular}, ::Type{T1}, ::Type{T2}
	) where {MS <: MusicalSpace, T1 <: PitchRepresentation, T2 <: PitchRepresentation}
	clockwise_dist = distance(MS, Clockwise, T1, T2)
	counterclockwise_dist = distance(MS, Counterclockwise, T1, T2)
	return min(clockwise_dist, counterclockwise_dist)
end

function distance(
		::Type{MS}, ::Type{Circular}, ::Type{Clockwise}, ::Type{T1}, ::Type{T2}
	) where {MS <: MusicalSpace, T1 <: PitchRepresentation, T2 <: PitchRepresentation}
	return mod(number(MS, T2) - number(MS, T1), length(MS))
end

function distance(
		::Type{MS}, ::Type{Circular}, ::Type{Counterclockwise}, ::Type{T1}, ::Type{T2}
	) where {MS <: MusicalSpace, T1 <: PitchRepresentation, T2 <: PitchRepresentation}
	return size(MS) - distance(MS, Clockwise, T1, T2)
end


## direction

"""
    direction(MS, PC1, PC2)

Determine the direction from PitchRepresentations `PC1` to `PC2` in a `MusicalSpace`.

Returns:
- For linear spaces: `Left` or `Right`
- For circular spaces: `Clockwise` or `Counterclockwise` (whichever is shorter)
"""
function direction(
		::Type{MS}, ::Type{PC1}, ::Type{PC2}
	) where {MS <: MusicalSpace, PC1, PC2}
	return direction(MS, TopologyStyle(MS), PC1, PC2)
end

function direction(
		::Type{MS}, ::Type{Linear}, ::Type{PC1}, ::Type{PC2}
	) where {MS <: MusicalSpace, PC1, PC2}
	return number(MS, PC1) > number(MS, PC2) ? Left : Right
end

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

"""
    is_enharmonic(PC1, PC2)

Check if two `PitchClass`es are enharmonic (represent the same pitch).

Two pitch classes are enharmonic if their positions on the LineOfFifths differs by a multiple of 12.
"""
is_enharmonic(::Type{PC1}, ::Type{PC2}) where {PC1 <: PitchClass, PC2 <: PitchClass} = 
	mod(distance(LineOfFifths, PC1, PC2), 12) == 0

"""
    find_enharmonics(PC1, PC2 = D♮, n)

Find the `n` enharmonic equivalents of `PC1` closest to reference pitch `PC2` on the LineOfFifths.

Returns an iterator of `PitchClass`es sorted by proximity to `PC2` (D♮ by defualt, because
that is the center or the LineOfFifths, and the notes closest to the center will be the ones
with the fewest accidentals).
"""
function find_enharmonics(::Type{PC1}, ::Type{PC2}, n::Integer) where {PC1 <: PitchClass, PC2 <: PitchClass}
	start = number(LineOfFifths, PC1)
	reference = number(LineOfFifths, PC2)
	k = round(Integer, -start / 12)
	m = start + 12 * k
	radius = n * 12
	rng = sort(m .+ -radius:12:radius, by = x -> abs(x - reference))
	return (PitchClass(LineOfFifths, i) for i in Iterators.take(rng, n))
end

find_enharmonics(::Type{PC}, n::Int) where {PC <: PitchClass} = 
	find_enharmonics(PC, D♮, n)



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


## expression support for integer arithmetic on pitch classes (evaluated within indexing exprs)
# todo: these need to work on letter names and pitches, too

struct SpaceExpr{Op, Arg1, Arg2} end

Base.:+(::Type{PC}, n::Integer) where {PC <: PitchClass} = SpaceExpr{:+, PC, Val{n}}
Base.:-(::Type{PC}, n::Integer) where {PC <: PitchClass} = SpaceExpr{:-, PC, Val{n}}

# todo: refactor this to use my Direction traits
function evaluate_in_space(::Type{S}, ::Type{SpaceExpr{Op, PC, Val{N}}}) where {S <: MusicalSpace, Op, PC, N}
	base_pos = number(S, PC)
	return Op == :+ ? base_pos + N : base_pos - N
end

evaluate_in_space(::Type{S}, ::Type{PC}) where {S <: MusicalSpace, PC <: PitchClass} = number(S, PC)
evaluate_in_space(::Type{S}, ::Type{L}) where {S <: MusicalSpace, L <: LetterName} = number(S, L)
evaluate_in_space(::Type{S}, n::Integer) where {S <: MusicalSpace} = n


## range-like call syntax for indexing into a space

function (::Type{S})(start, len::Number) where S <: MusicalSpace
	start_pos = evaluate_in_space(S, start)
	return space_range(S, TopologyStyle(S), start_pos, 1, len)
end

function (::Type{S})(start, stop) where S <: MusicalSpace
	start_pos = evaluate_in_space(S, start)
	stop_pos = evaluate_in_space(S, stop)
	len = calculate_length(S, TopologyStyle(S), start_pos, stop_pos, 1)
	return space_range(S, TopologyStyle(S), start_pos, 1, len)
end

function (::Type{S})(start, step::Number, len::Number) where S <: MusicalSpace
	start_pos = evaluate_in_space(S, start)
	return space_range(S, TopologyStyle(S), start_pos, step, len)
end

function (::Type{S})(start, step::Number, stop) where S <: MusicalSpace
	start_pos = evaluate_in_space(S, start)
	stop_pos = evaluate_in_space(S, stop)
	len = calculate_length(S, TopologyStyle(S), start_pos, stop_pos, step)
	return space_range(S, TopologyStyle(S), start_pos, step, len)
end


## helpers for the indexing fns above

function calculate_length(
		::Type{S}, ::Type{Linear}, start::Integer, stop::Integer, step::Integer
	) where S <: MusicalSpace
	(step > 0 && stop < start) && return 0
	(step < 0 && stop > start) && return 0
	return div(stop - start, step) + 1
end

function calculate_length(
		::Type{S}, ::Type{Circular}, start::Int, stop::Int, step::Int
	) where S <: MusicalSpace
	len = Base.length(S)
	start = mod(start, len)
	stop = mod(stop, len)
	if step > 0
		# Forward direction - take shortest path
		dist = start <= stop ? stop - start : (len - start) + stop
	else
		# Backward direction - take shortest path
		dist = start >= stop ? start - stop : start + (len - stop)
	end
	return div(dist, abs(step)) + 1
end

function space_range(
		::Type{S}, ::Type{Linear}, start::Integer, step::Integer, len::Integer
	) where S <: MusicalSpace
	return (eltype(S)(S, start + i * step) for i in 0:len-1)
end

function space_range(
		::Type{S}, ::Type{Circular}, start::Integer, step::Integer, len::Integer
	) where S <: MusicalSpace
	space_len = Base.length(S)
	return (eltype(S)(S, mod(start + i * step, space_len)) for i in 0:len-1)
end

