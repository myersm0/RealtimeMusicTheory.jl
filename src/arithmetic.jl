
@generated function Base.:+(::Type{PC}, ::Type{ChromaticStep{N}}) where {PC <: PitchClass, N}
	N == 0 && return PC
	if N > 0
		spellings = [C♮, C♯, D♮, D♯, E♮, F♮, F♯, G♮, G♯, A♮, A♯, B♮]
	else 
		spellings = [C♮, D♭, D♮, E♭, E♮, F♮, G♭, G♮, A♭, A♮, B♭, B♮]
	end
	target_semi = mod(semitone(PC) + N, 12)
	return spellings[target_semi + 1]
end

@generated function Base.:+(::Type{Pitch{PC, Register}}, ::Type{ChromaticStep{N}}) where {PC, Register, N}
	# calculate new pitch class
	new_pc = PC + ChromaticStep{N}
	
	# calculate register change
	start_semi = semitone(PC)  # Could be > 11 for B#, etc
	end_semi = semitone(new_pc)
	total_change = start_semi + N
	register_change = div(total_change, 12)
	new_register = Register + register_change

	return :(Pitch{$new_pc, $new_register})
end

@generated function Base.:+(::Type{PC}, ::Type{Interval{N, Q}}) where {PC <: PitchClass, N, Q}
	start_letter = letter(PC)
	# intervals are 1-indexed, so M3 = 3 letter names
	target_letter = letter_step(start_letter, N - 1)
	
	# calculate semitone distance
	chromatic_step = ChromaticStep(Interval{N, Q})
	semi_distance = chromatic_step.parameters[1]
	
	start_semi = mod(semitone(PC), 12)
	target_semi = mod(start_semi + semi_distance, 12)
	
	# what accidental do we need on the target letter?
	target_natural_semi = chromatic_position(target_letter)
	offset = target_semi - target_natural_semi
	
	# normalize offset to -2..2 range
	if offset > 2
		offset -= 12
	elseif offset < -2
		offset += 12
	end
	
	acc = offset == -2 ? DoubleFlat :
		  offset == -1 ? Flat :
		  offset == 0 ? Natural :
		  offset == 1 ? Sharp :
		  offset == 2 ? DoubleSharp :
		  error("Invalid accidental offset: $offset for interval $N$Q")
	
	return :(PitchClass{$target_letter, $acc})
end

@generated function Base.:+(::Type{Pitch{PC, Register}}, ::Type{Interval{N, Q}}) where {PC, Register, N, Q}
	# first get the new pitch class
	new_pc = PC + Interval{N, Q}
	
	# calculate register change from letter progression
	start_letter = letter(PC)
	letter_steps = N - 1
	start_pos = letter_position(start_letter)
	
	# every 7 letter steps = 1 octave
	register_change = div(start_pos + letter_steps, 7)
	new_register = Register + register_change
	
	return :(Pitch{$new_pc, $new_register})
end

# Scale-aware movement (remains at pitch class level)
@generated function Base.:+(
	::Type{PC}, 
	::Type{GenericInterval{N}},
	::Type{Scale{PCs}}
) where {PC <: PitchClass, N, PCs}
	pos = findfirst(==(PC), PCs.parameters)
	isnothing(pos) && error("Pitch class not in scale")
	
	# Move N steps in scale (0-indexed internally)
	new_pos = mod(pos - 1 + N, length(PCs.parameters)) + 1
	
	return :($(PCs.parameters[new_pos]))
end

# Pitch movement in scale context
@generated function Base.:+(
	::Type{Pitch{PC, Register}},
	::Type{GenericInterval{N}}, 
	::Type{Scale{PCs}}
) where {PC, Register, N, PCs}
	# Get new pitch class
	new_pc = PC + GenericInterval{N} in Scale{PCs}
	
	# Calculate register changes
	pos = findfirst(==(PC), PCs.parameters)
	new_pos = mod(pos - 1 + N, length(PCs.parameters)) + 1
	
	# Register changes when we wrap around the scale
	register_change = div(pos - 1 + N, length(PCs.parameters))
	
	new_reg = Register + register_change
	
	return :(Pitch{$new_pc, $new_reg})
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

@generated function negate(::Type{ChromaticStep{N}}) where N
	return :(ChromaticStep($(-N)))
end

@generated function negate(::Type{DiatonicStep{N}}) where N
	return :(DiatonicStep($(-N)))
end

@generated function negate(::Type{GenericInterval{N}}) where N
	return :(GenericInterval($(-N)))
end

Base.:-(p::Type{<:Pitch}, s::Type{<:SimpleStep}) = p + negate(s)
Base.:-(pc::Type{<:PitchClass}, s::Type{<:SimpleStep}) = pc + negate(s)

@generated function Base.:-(::Type{PC}, ::Type{Interval{N, Q}}) where {PC <: PitchClass, N, Q}
	start_letter = letter(PC)
	# go down N-1 letter names
	target_letter = letter_step(start_letter, -(N - 1))
	# calculate semitone distance (negative)
	chromatic_step = ChromaticStep(Interval{N, Q})
	semi_distance = -(chromatic_step.parameters[1])
	
	start_semi = mod(semitone(PC), 12)
	target_semi = mod(start_semi + semi_distance, 12)  # mod handles negative
	
	target_natural_semi = chromatic_position(target_letter)
	offset = target_semi - target_natural_semi
	
	if offset > 2
		offset -= 12
	elseif offset < -2
		offset += 12
	end
	
	acc = offset == -2 ? DoubleFlat :
		offset == -1 ? Flat :
		offset == 0 ? Natural :
		offset == 1 ? Sharp :
		offset == 2 ? DoubleSharp :
		error("Invalid accidental offset: $offset")
	
	return :(PitchClass{$target_letter, $acc})
end

# For Pitch, also handle register changes
@generated function Base.:-(::Type{Pitch{PC, Reg}}, ::Type{Interval{N, Q}}) where {PC, Reg, N, Q}
	new_pc = PC - Interval{N, Q}
	
	# calculate register change
	start_letter = letter(PC)
	letter_steps = -(N - 1)  # Negative for going down
	start_pos = letter_position(start_letter)
	
	# going down: negative letter steps can decrease register
	register_change = div(start_pos + letter_steps, 7)
	new_reg = Reg + register_change

	return :(Pitch{$new_pc, $new_reg})
end

