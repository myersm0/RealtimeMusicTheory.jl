
@generated function Base.:+(::Type{Pitch{PC, Oct}}, ::Type{ChromaticStep{N}}) where {PC, Oct, N}
	current_semi = semitone(PC)
	total_semi = current_semi + N
	octave_change = div(total_semi, 12)
	new_octave = Oct + octave_change
	new_pc = add_semitones(PC, N)
	return :(Pitch{$new_pc, $new_octave})
end

@generated function Base.:+(::Type{Pitch{PC, Oct}}, ::Type{DiatonicStep{N}}) where {PC, Oct, N}
	current_letter = letter(PC)
	current_acc = accidental(PC)
	new_letter = letter_step(current_letter, N)
	current_pos = letter_position(current_letter)
	octave_change = div(current_pos + N, 7)
	new_octave = Oct + octave_change
	new_pc = PitchClass{new_letter, current_acc}
	return :(Pitch{$new_pc, $new_octave})
end

@generated function Base.:+(::Type{Pitch{PC, Oct}}, ::Type{Interval{N, Q}}) where {PC, Oct, N, Q}
	start_letter = letter(PC)
	# Calculate target letter (N-1 because intervals are 1-indexed)
	letter_steps = N - 1
	target_letter = letter_step(start_letter, letter_steps)
	# Calculate semitones needed
	chromatic_step = to_chromatic_step(Interval{N, Q})
	semi_needed = chromatic_step.parameters[1]
	
	# Current position
	start_semi = semitone(PC)
	target_semi = start_semi + semi_needed
	
	# Calculate octave
	start_pos = letter_position(start_letter)
	octave_from_letters = div(start_pos + letter_steps, 7)
	new_octave = Oct + octave_from_letters + div(target_semi, 12)
	
	# Determine accidental needed
	target_natural_semi = chromatic_position(target_letter)
	target_semi_in_octave = mod(target_semi, 12)
	required_offset = target_semi_in_octave - target_natural_semi
	
	# Normalize offset
	if required_offset > 2
		required_offset -= 12
	elseif required_offset < -2
		required_offset += 12
	end
	
	# Map to accidental
	acc = required_offset == -2 ? DoubleFlat :
		  required_offset == -1 ? Flat :
		  required_offset == 0 ? Natural :
		  required_offset == 1 ? Sharp :
		  required_offset == 2 ? DoubleSharp :
		  Natural  # Fallback
	
	new_pc = PitchClass{target_letter, acc}
	
	return :(Pitch{$new_pc, $new_octave})
end

# Add generic interval within scale context
@generated function Base.:+(
		::Type{Pitch{PC, Oct}}, 
		::Type{GenericInterval{N}},
		::Type{Scale{PCs}}
	) where {PC, Oct, N, PCs}
	pos = scale_position(Scale{PCs}, PC)
	!isnothing(pos) || return :(error("Pitch class not in scale"))
	new_pos = mod(pos + N, length(PCs.parameters))
	new_pc = PCs.parameters[new_pos + 1]
	octave_change = div(pos + N, length(PCs.parameters))
	new_octave = Oct + octave_change
	return :(Pitch{$new_pc, $new_octave})
end

# Allow instances as well as types
Base.:+(p::Pitch, s::Step) = typeof(p) + typeof(s)
Base.:+(p::Pitch, g::Type{<:GenericInterval}, s::Type{<:Scale}) = typeof(p) + g in s

# Subtraction (reverse the step)
Base.:-(p::Type{<:Pitch}, s::Type{<:Step}) = p + negate(s)

@generated function negate(::Type{ChromaticStep{N}}) where N
	:(ChromaticStep{$(-N)}())
end

@generated function negate(::Type{DiatonicStep{N}}) where N
	:(DiatonicStep{$(-N)}())
end

@generated function negate(::Type{GenericInterval{N}}) where N
	:(GenericInterval{$(-N)}())
end

