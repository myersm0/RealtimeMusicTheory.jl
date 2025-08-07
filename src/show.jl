
function Base.show(io::IO, ::Type{PitchClass{L, A}}) where {L, A}
	print(io, L)
	print(io, A)
end
	
function Base.show(io::IO, ::Type{Accidental{N}}) where N
	N == 0 && return print(io, "♮")
	N < 0 && return print(io, "♭"^(-N))
	return print(io, "♯"^N)
end

