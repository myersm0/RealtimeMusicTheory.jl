
struct Interval{Semitones} end

abstract type IntervalQuality end
struct Perfect <: IntervalQuality end
struct Major <: IntervalQuality end
struct Minor <: IntervalQuality end
struct Augmented <: IntervalQuality end
struct Diminished <: IntervalQuality end

struct QualifiedInterval{Number, Quality <: IntervalQuality} end

# ============= Interval construction =============

# From two pitches - calculate the interval
@generated function Interval(
		p1::Type{Pitch{PC1, Oct1}}, 
		p2::Type{Pitch{PC2, Oct2}}
	) where {PC1, Oct1, PC2, Oct2}
	semi1 = semitone(PC1) + 12 * Oct1
	semi2 = semitone(PC2) + 12 * Oct2
	# Always measure upward
	if semi2 < semi1
		semi1, semi2 = semi2, semi1
	end
	semitone_distance = semi2 - semi1
	:(Interval{$semitone_distance}())
end

function Interval(number::Int, quality::Type{<:IntervalQuality})
	QualifiedInterval{number, quality}()
end

# Common interval constructors
# Interval(2, Minor) # Minor second
# Interval(3, Major) # Major third
# Interval(5, Perfect) # Perfect fifth

# ===== Distances =====

abstract type DistanceMetric end
struct SemitoneDistance <: DistanceMetric end
struct LetterDistance <: DistanceMetric end
struct IntervalNumber <: DistanceMetric end

distance(::Type{SemitoneDistance}, ::Interval{S}) where S = S
distance(::Type{SemitoneDistance}, ::QualifiedInterval{N, Q}) where {N, Q} = 
	interval_semitones(N, Q)

# Letter distance (for proper spelling)
@generated function distance(
		::Type{LetterDistance}, 
		p1::Type{Pitch{PC1, Oct1}}, 
		p2::Type{Pitch{PC2, Oct2}}
	) where {PC1, Oct1, PC2, Oct2}
	pos1 = letter_position(letter(PC1))
	pos2 = letter_position(letter(PC2))
	
	# Account for octave changes
	octave_diff = Oct2 - Oct1
	letter_dist = pos2 - pos1 + 7 * octave_diff
	
	# Make sure it's positive
	if letter_dist < 0
		letter_dist = -letter_dist
	end
	
	:($letter_dist)
end

# Interval number (1 = unison, 2 = second, etc.)
interval_number(::QualifiedInterval{N, Q}) where {N, Q} = N

# ===== Interval to semitones mapping =====

# Define semitone values for qualified intervals
semitones(::Type{QualifiedInterval{1, Perfect}}) = 0
semitones(::Type{QualifiedInterval{1, Augmented}}) = 1
semitones(::Type{QualifiedInterval{2, Minor}}) = 1
semitones(::Type{QualifiedInterval{2, Major}}) = 2
semitones(::Type{QualifiedInterval{2, Augmented}}) = 3
semitones(::Type{QualifiedInterval{3, Diminished}}) = 2
semitones(::Type{QualifiedInterval{3, Minor}}) = 3
semitones(::Type{QualifiedInterval{3, Major}}) = 4
semitones(::Type{QualifiedInterval{3, Augmented}}) = 5
semitones(::Type{QualifiedInterval{4, Diminished}}) = 4
semitones(::Type{QualifiedInterval{4, Perfect}}) = 5
semitones(::Type{QualifiedInterval{4, Augmented}}) = 6
semitones(::Type{QualifiedInterval{5, Diminished}}) = 6
semitones(::Type{QualifiedInterval{5, Perfect}}) = 7
semitones(::Type{QualifiedInterval{5, Augmented}}) = 8
semitones(::Type{QualifiedInterval{6, Minor}}) = 8
semitones(::Type{QualifiedInterval{6, Major}}) = 9
semitones(::Type{QualifiedInterval{7, Diminished}}) = 9
semitones(::Type{QualifiedInterval{7, Minor}}) = 10
semitones(::Type{QualifiedInterval{7, Major}}) = 11
semitones(::Type{QualifiedInterval{8, Perfect}}) = 12

# ===== Smarter pitch arithmetic =====

# Simple interval addition (may not spell correctly)
Base.:+(p::Pitch, ::Interval{S}) where S = p + Interval{S}

# General case using modular arithmetic
letter_position(::Type{C}) = 0
letter_position(::Type{D}) = 1
letter_position(::Type{E}) = 2
letter_position(::Type{F}) = 3
letter_position(::Type{G}) = 4
letter_position(::Type{A}) = 5
letter_position(::Type{B}) = 6


# Qualified interval addition (spells correctly)
@generated function Base.:+(
		::Pitch{PC, Oct}, ::Type{QualifiedInterval{Number, Quality}}
	) where {PC, Oct, Number, Quality}
	# Step 1: Calculate target letter
	letter_distance = Number - 1  # Interval of a 3rd spans 2 letter names
	target_pos = mod(letter_position(letter(PC)) + letter_distance, 7)
	letters = [C, D, E, F, G, A, B]
	target_letter = letters[target_pos + 1]
	
	# Step 2: Calculate semitones
	start_semi = semitone(PC)# + offset(Acc)
	interval_semi = semitones(QualifiedInterval{Number, Quality})
	total_semi = start_semi + interval_semi
	
	# Step 3: Calculate octaves
	octave_from_letters = div(letter_position(letter(PC)) + letter_distance, 7)
	octave_from_semis = div(start_semi + interval_semi, 12)
	new_octave = Oct + octave_from_letters
	
	# Step 4: Determine accidental needed
	target_natural_semi = semitone(target_letter)
	target_semi_in_octave = mod(total_semi, 12)
	required_offset = target_semi_in_octave - target_natural_semi
	
	# Handle wraparound
	if required_offset > 2
		required_offset -= 12
		new_octave += 1
	elseif required_offset < -2
		required_offset += 12
		new_octave -= 1
	end
	
	# Map to accidental
	acc_map = Dict(
		-2 => DoubleFlat,
		-1 => Flat,
		0 => Natural,
		1 => Sharp,
		2 => DoubleSharp
	)
	
	new_acc = get(acc_map, required_offset, Natural)
	
	:(Pitch($target_letter, $new_acc, $new_octave))
end

# ===== Convenient interval names =====

const m2 = QualifiedInterval{2, Minor}()      # Minor second
const M2 = QualifiedInterval{2, Major}()      # Major second  
const m3 = QualifiedInterval{3, Minor}()      # Minor third
const M3 = QualifiedInterval{3, Major}()      # Major third
const P4 = QualifiedInterval{4, Perfect}()    # Perfect fourth
const A4 = QualifiedInterval{4, Augmented}()  # Augmented fourth
const d5 = QualifiedInterval{5, Diminished}() # Diminished fifth
const P5 = QualifiedInterval{5, Perfect}()    # Perfect fifth
const m6 = QualifiedInterval{6, Minor}()      # Minor sixth
const M6 = QualifiedInterval{6, Major}()      # Major sixth
const m7 = QualifiedInterval{7, Minor}()      # Minor seventh
const M7 = QualifiedInterval{7, Major}()      # Major seventh
const P8 = QualifiedInterval{8, Perfect}()    # Perfect octave


