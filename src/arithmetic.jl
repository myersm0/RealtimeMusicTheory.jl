
@generated function Base.:+(::Type{Pitch{PC, Register}}, ::Type{ChromaticStep{N}}) where {PC, Register, N}
	current_semi = semitone(PC)
	total_semi = current_semi + N
	register_change = div(total_semi, 12)
	new_register = Register + register_change
	new_pc = add_semitones(PC, N)
	return :(Pitch{$new_pc, $new_register})
end

@generated function Base.:+(::Type{Pitch{PC, Register}}, ::Type{DiatonicStep{N}}) where {PC, Register, N}
	current_letter = letter(PC)
	current_acc = accidental(PC)
	new_letter = letter_step(current_letter, N)
	current_pos = letter_position(current_letter)
	register_change = div(current_pos + N, 7)
	new_register = Register + register_change
	new_pc = PitchClass{new_letter, current_acc}
	return :(Pitch{$new_pc, $new_register})
end

@generated function Base.:+(::Type{Pitch{PC, Register}}, ::Type{Interval{N, Q}}) where {PC, Register, N, Q}
	start_letter = letter(PC)
	# Calculate target letter (N-1 because intervals are 1-indexed)
	letter_steps = N - 1
	target_letter = letter_step(start_letter, letter_steps)
	# Calculate semitones needed
	chromatic_step = to_chromatic_step(Interval{N, Q})
	semi_needed = chromatic_step.parameters[1]
	
	# Current position (just pitch class, not with octave)
	start_pc_semi = semitone(PC)
	
	# Calculate octave changes from letter position
	start_pos = letter_position(start_letter)
	register_from_letters = div(start_pos + letter_steps, 7)
	
	# Calculate the target semitone within an octave
	target_semi_total = start_pc_semi + semi_needed
	register_from_semis = div(target_semi_total, 12)
	target_semi_in_register = mod(target_semi_total, 12)
	
	# New octave (only add the change, not absolute position)
	new_register = Register + register_from_letters
	
	# Determine accidental needed
	target_natural_semi = chromatic_position(target_letter)
	required_offset = target_semi_in_register - target_natural_semi
	
	# Normalize offset to -12..12 range first
	if required_offset > 6
		required_offset -= 12
		new_register += 1
	elseif required_offset < -6
		required_offset += 12
		new_register -= 1
	end
	
	# Map to accidental
	acc = required_offset == -2 ? DoubleFlat :
		required_offset == -1 ? Flat :
		required_offset == 0 ? Natural :
		required_offset == 1 ? Sharp :
		required_offset == 2 ? DoubleSharp :
		Natural # should never reach this
	
	new_pc = PitchClass{target_letter, acc}
	return :(Pitch{$new_pc, $new_register})
end

# Add generic interval within scale context
@generated function Base.:+(
		::Type{Pitch{PC, Register}}, 
		::Type{GenericInterval{N}},
		::Type{Scale{PCs}}
	) where {PC, Register, N, PCs}
	pos = scale_position(Scale{PCs}, PC)
	!isnothing(pos) || return :(error("Pitch class not in scale"))
	new_pos = mod(pos + N, length(PCs.parameters))
	new_pc = PCs.parameters[new_pos + 1]
	register_change = div(pos + N, length(PCs.parameters))
	new_register = Register + register_change
	return :(Pitch{$new_pc, $new_register})
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

