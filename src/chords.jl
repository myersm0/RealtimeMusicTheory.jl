
struct Chord{PitchClasses <: Tuple} end

@generated function triad(::Type{Scale{PCs}}, ::Type{ScaleDegree{N}}) where {PCs, N}
	root = scale_pitch(Scale{PCs}, ScaleDegree{N})
	third = scale_pitch(Scale{PCs}, ScaleDegree{mod1(N+2, 7)})
	fifth = scale_pitch(Scale{PCs}, ScaleDegree{mod1(N+4, 7)})
	return :(Chord{Tuple{$root, $third, $fifth}})
end

@generated function quality(::Type{Chord{PCs}}) where {PCs}
	length(PCs.parameters) >= 3 || return :(nothing)
	root, third, fifth = PCs.parameters[1:3]
	root_semi = semitone(root)
	third_semi = semitone(third)
	fifth_semi = semitone(fifth)
	third_interval = mod(third_semi - root_semi, 12)
	fifth_interval = mod(fifth_semi - root_semi, 12)
	(third_interval == 4 && fifth_interval == 7) && return :(Major)
	(third_interval == 3 && fifth_interval == 7) && return :(Minor)
	(third_interval == 3 && fifth_interval == 6) && return :(Diminished)
	(third_interval == 4 && fifth_interval == 8) && return :(Augmented)
	return :(nothing)
end

