
function Base.:+(::Type{L}, ::Type{GenericInterval{N}}) where {L <: LetterName, N}
	return move(LetterSpace, L, N)
end

# todo: should this return a PC?
function Base.:+(::Type{PC}, ::Type{GenericInterval{N}}) where {PC <: PitchClass, N}
	return move(LetterSpace, letter(PC), N)
end

# todo: should it be move's responsibility to spell correctly?

# for intervals 2, 3, 6, 7 (i.e. where major and minor qualities exist), 
# minor denotes -1, diminished -2, and augmented +1, relative to major;
# for intervals 1, 4, 5, 8 (i.e. ones where perfect quality exists),
# diminished denotes - 1, augmenting denotes + 1
# note that MusicTheory.jl is incorrect re: diminished seconds

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

@generated function semitones(interval::Type{Interval{N, Quality}}) where {N, Quality}
    simple_n = (N - 1) % 7 + 1 # 1-based (1=unison, 8=octave)
    octaves = (N - 1) ÷ 7
    simple_semitones = base(Interval{simple_n, Quality}) + offset(Interval{simple_n, Quality})
	 return :($simple_semitones + 12 * $octaves)
end

Base.:+(::Type{PC}, ::Type{Interval{N, Quality}}) where {PC <: PitchClass, N, Quality} =
    move(PitchClassSpace, PC, semitones(Interval{N, Quality}))




function Base.:+(::Type{PC}, ::Type{SpaceStep{S, N}}) where {PC <: PitchClass, S, N}
	return move(S, PC, N)
end

function Base.:+(::Type{L}, ::Type{SpaceStep{S, N}}) where {L <: LetterName, S <: GenericSpace, N}
	return move(S, L, N)
end

# todo: this is not correct
@generated function Base.:+(::Type{PC}, ::Type{DiatonicStep{N}}) where {PC <: PitchClass, N}
	current_letter = letter(PC)
	current_acc = accidental(PC)
	new_letter = move(LetterSpace, current_letter, N)
	result = PitchClass(new_letter, current_acc)
	:($result)
end

# is this better?
@generated function Base.:+(::Type{PC}, ::Type{Interval{N, Quality}}) where {PC <: PitchClass, N, Quality}
    target_letter = letter(PC) + GenericInterval{N-1}
    target_semi = mod(semitone(PC) + semitones(Interval{N, Quality}), 12)
    acc_offset = target_semi - chromatic_position(target_letter)
    acc_offset > 2 && (acc_offset -= 12)
    acc_offset < -2 && (acc_offset += 12)
    return :(PitchClass($target_letter, Accidental($acc_offset)))
end


@generated function Base.:+(::Type{PC}, ::Type{SpaceStep{PitchClassSpace, N}}) where {PC <: PitchClass, N}
	target_semi = mod(semitone(PC) + N, 12)
	
	# Use line of fifths to find best spelling
	# Key insight: any 7 consecutive positions in LineOfFifths form a proper diatonic collection
	current_fifth_pos = number(LineOfFifths, PC)
	
	# Find the diatonic collection containing our starting pitch
	# This is the 7-note window in LineOfFifths centered near our position
	window_start = current_fifth_pos - 3
	window_end = current_fifth_pos + 3
	
	# Generate candidates from this window and adjacent positions
	candidates = Type[]
	for fifth_pos in (window_start-1):(window_end+1)
		candidate = PitchClass(LineOfFifths, fifth_pos)
		if mod(semitone(candidate), 12) == target_semi
			push!(candidates, candidate)
		end
	end
	
	# Choose the candidate closest to our starting position in LineOfFifths
	# This ensures smooth voice leading and proper spelling
	best_candidate = candidates[1]
	min_distance = abs(number(LineOfFifths, best_candidate) - current_fifth_pos)
	
	for candidate in candidates[2:end]
		dist = abs(number(LineOfFifths, candidate) - current_fifth_pos)
		if dist < min_distance
			min_distance = dist
			best_candidate = candidate
		end
	end
	
	:($best_candidate)
end

# Interval addition using line of fifths for proper spelling
@generated function Base.:+(::Type{PC}, ::Type{Interval{D, C, Q}}) where {PC <: PitchClass, D, C, Q}
	# Move in letter space
	start_letter = letter(PC)
	target_letter = move(LetterSpace, start_letter, D - 1)  # D is 1-indexed
	
	# Calculate required semitone position
	target_semi = mod(semitone(PC) + C, 12)
	
	# Use line of fifths to determine proper accidental
	# The 7-note diatonic collection containing PC should inform our spelling
	start_fifth_pos = number(LineOfFifths, PC)
	
	# Find which accidental on target_letter gives us the right semitones
	# while staying close in the line of fifths
	candidates = []
	for acc_offset in -2:2  # DoubleFlat to DoubleSharp
		candidate = PitchClass(target_letter, Accidental(acc_offset))
		if mod(semitone(candidate), 12) == target_semi
			fifth_dist = abs(number(LineOfFifths, candidate) - start_fifth_pos)
			push!(candidates, (candidate, fifth_dist))
		end
	end
	
	# Choose spelling with minimum fifth distance
	best = sort(candidates, by = x -> x[2])[1][1]
	:($best)
end

# Multiple dispatch for register changes
@generated function register_change(
	::Type{SpaceStep{PitchClassSpace, N}}, 
	::Type{Pitch{PC, Reg}}
) where {PC, Reg, N}
	# For chromatic movement, we need the actual result to check wrapping
	new_pc = PC + SpaceStep{PitchClassSpace, N}
	start_semi = mod(semitone(PC), 12)
	end_semi = mod(semitone(new_pc), 12)
	
	# Did we cross an octave boundary?
	if N > 0
		# Moving up: did we wrap from 11 to 0?
		wrapped = end_semi < start_semi ? 1 : 0
	else
		# Moving down: did we wrap from 0 to 11?
		wrapped = end_semi > start_semi ? -1 : 0
	end
	
	base_octaves = div(N, 12)
	:($(base_octaves + wrapped))
end

@generated function register_change(
	::Type{SpaceStep{LetterSpace, N}},
	::Type{Pitch{PC, Reg}}
) where {PC, Reg, N}
	# Simple for letter space
	:($(div(N, 7)))
end

@generated function register_change(
	::Type{DiatonicStep{N}},
	::Type{Pitch{PC, Reg}}
) where {PC, Reg, N}
	# Need to consider current position for wrapping
	start_pos = letter_position(letter(PC))
	end_pos = mod(start_pos + N, 7)
	
	# How many times did we wrap?
	wraps = div(start_pos + N, 7)
	:($(wraps))
end

# Interval register change
@generated function register_change(
	::Type{Interval{D, C, Q}},
	::Type{Pitch{PC, Reg}}
) where {PC, Reg, D, C, Q}
	# Based on diatonic distance
	start_pos = letter_position(letter(PC))
	letter_steps = D - 1
	wraps = div(start_pos + letter_steps, 7)
	:($(wraps))
end

# Generic pitch space step
@generated function Base.:+(
	::Type{Pitch{PC, Reg}}, 
	step::Type{<:Step}
) where {PC, Reg}
	new_pc = PC + step
	reg_change = register_change(step, Pitch{PC, Reg})
	new_reg = Reg + reg_change
	:(Pitch{$new_pc, $new_reg})
end

# Special handling for interval addition to preserve octave calculation
@generated function Base.:+(
	::Type{Pitch{PC, Reg}}, 
	::Type{Interval{D, C, Q}}
) where {PC, Reg, D, C, Q}
	new_pc = PC + Interval{D, C, Q}
	reg_change = register_change(Interval{D, C, Q}, Pitch{PC, Reg})
	new_reg = Reg + reg_change
	:(Pitch{$new_pc, $new_reg})
end

# Scale-aware movement
@generated function Base.:+(
	::Type{PC}, 
	::Type{GenericInterval{N}},
	scale::Type{Scale{PCs}}
) where {PC <: PitchClass, N, PCs}
	# Movement in scale space
	scale_space = ScaleSpace{scale}
	result = move(scale_space, PC, N)
	:($result)
end

# Subtraction as inverse
Base.:-(pc::Type{<:PitchClass}, step::Type{<:Step}) = pc + negate(step)
Base.:-(p::Type{<:Pitch}, step::Type{<:Step}) = p + negate(step)

@generated function negate(::Type{SpaceStep{S, N}}) where {S, N}
	:(SpaceStep{$S, $(-N)})
end

@generated function negate(::Type{DiatonicStep{N}}) where N
	:(DiatonicStep{$(-N)})
end

@generated function negate(::Type{Interval{D, C, Q}}) where {D, C, Q}
	# Negating an interval - both distances negate
	# but we need to handle the 1-indexing properly
	new_d = 2 - D  # If D=3 (third), negative is -1, which as 1-indexed is 1
	:(Interval{$new_d, $(-C), $Q})
end

@generated function negate(::Type{GenericInterval{N}}) where N
	:(GenericInterval{$(-N)})
end

# Find interval between pitch classes using line of fifths
@generated function interval_between(::Type{PC1}, ::Type{PC2}) where {PC1 <: PitchClass, PC2 <: PitchClass}
	# Letter distance
	letter_dist = number(LetterSpace, letter(PC2)) - number(LetterSpace, letter(PC1))
	if letter_dist < 0
		letter_dist += 7
	end
	diatonic = letter_dist + 1  # Convert to 1-indexed
	
	# Chromatic distance
	chromatic_dist = mod(semitone(PC2) - semitone(PC1), 12)
	
	# Determine quality from the distances
	# This is where the interval table logic would go
	# For now, simplified:
	quality = Perfect  # Placeholder
	gg
	:(Interval{$diatonic, $chromatic_dist, $quality})
end



