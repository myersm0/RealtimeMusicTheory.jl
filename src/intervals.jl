# intervals.jl - Updated for Pitch{PitchClass, Oct} composition

# ============= Interval Types =============

abstract type IntervalQuality end
struct Perfect <: IntervalQuality end
struct Major <: IntervalQuality end
struct Minor <: IntervalQuality end
struct Augmented <: IntervalQuality end
struct Diminished <: IntervalQuality end

struct Interval{Number, Quality <: IntervalQuality} end

# ============= Helper Functions for PitchClass =============

# Define operations directly on PitchClass to avoid awkward extractions
@generated function letter_position(::Type{PitchClass{L, A}}) where {L, A}
    pos = letter_position(L)
    :($pos)
end

@generated function semitone(::Type{PitchClass{L, A}}) where {L, A}
    semi = semitone(L) + offset(A)
    :($semi)
end

# ============= Interval Construction =============

# From two pitches - calculate the interval
@generated function Interval(
    p1::Type{Pitch{PC1, Oct1}}, 
    p2::Type{Pitch{PC2, Oct2}}
) where {PC1, Oct1, PC2, Oct2}
    # Get semitones directly from PitchClass
    semi1 = semitone(PC1) + 12 * Oct1
    semi2 = semitone(PC2) + 12 * Oct2
    
    # Always measure upward
    if semi2 < semi1
        PC1, Oct1, PC2, Oct2 = PC2, Oct2, PC1, Oct1
        semi1, semi2 = semi2, semi1
    end
    
    # Calculate letter distance using PitchClass directly
    pos1 = letter_position(PC1)
    pos2 = letter_position(PC2)
    
    # Letter distance including octaves
    letter_dist = pos2 - pos1 + 7 * (Oct2 - Oct1)
    if letter_dist < 0
        letter_dist += 7
    end
    
    # Interval number is letter distance + 1
    number = letter_dist + 1
    
    # Determine quality based on semitone distance
    semitone_dist = semi2 - semi1
    
    # This is simplified - full implementation would handle all cases properly
    if number in [1, 4, 5, 8]  # Perfect intervals
        expected_semi = number == 1 ? 0 : number == 4 ? 5 : number == 5 ? 7 : 12
        if semitone_dist == expected_semi
            quality = Perfect
        elseif semitone_dist > expected_semi
            quality = Augmented
        else
            quality = Diminished
        end
    else  # Major/minor intervals
        # Simplified logic
        quality = Major
    end
    
    :(Interval{$number, $quality}())
end

# Constructor from number and quality
Interval(number::Int, ::Type{Q}) where {Q <: IntervalQuality} = 
    Interval{number, Q}()

# ============= Distance Metrics =============

abstract type DistanceMetric end
struct SemitoneMetric <: DistanceMetric end
struct LetterMetric <: DistanceMetric end
struct DiatonicMetric <: DistanceMetric end

# Distance for simple intervals
distance(::Type{SemitoneMetric}, ::Type{Interval{N, Q}}) where {N, Q} = 
    semitones(Interval{N, Q})

# Letter distance between pitches
@generated function distance(
    ::Type{LetterMetric}, 
    p1::Type{Pitch{PC1, Oct1}}, 
    p2::Type{Pitch{PC2, Oct2}}
) where {PC1, Oct1, PC2, Oct2}
    # Work directly with PitchClass
    pos1 = letter_position(PC1)
    pos2 = letter_position(PC2)
    
    octave_diff = Oct2 - Oct1
    letter_dist = pos2 - pos1 + 7 * octave_diff
    
    # Make positive
    if letter_dist < 0
        letter_dist = -letter_dist
    end
    
    :($letter_dist)
end

# ============= Interval to Semitones Mapping =============

@generated function semitones(::Type{Interval{N, Q}}) where {N, Q}
    # Complete mapping
    table = Dict(
        (1, Perfect) => 0,
        (1, Augmented) => 1,
        (2, Diminished) => 0,
        (2, Minor) => 1,
        (2, Major) => 2,
        (2, Augmented) => 3,
        (3, Diminished) => 2,
        (3, Minor) => 3,
        (3, Major) => 4,
        (3, Augmented) => 5,
        (4, Diminished) => 4,
        (4, Perfect) => 5,
        (4, Augmented) => 6,
        (5, Diminished) => 6,
        (5, Perfect) => 7,
        (5, Augmented) => 8,
        (6, Diminished) => 7,
        (6, Minor) => 8,
        (6, Major) => 9,
        (6, Augmented) => 10,
        (7, Diminished) => 9,
        (7, Minor) => 10,
        (7, Major) => 11,
        (7, Augmented) => 12,
        (8, Diminished) => 11,
        (8, Perfect) => 12,
        (8, Augmented) => 13,
    )
    
    result = get(table, (N, Q), 0)
    :($result)
end

# ============= Pitch Arithmetic =============

# Add interval to pitch type
@generated function Base.:+(::Type{Pitch{PC, Oct}}, ::Type{Interval{N, Q}}) where {PC, Oct, N, Q}
    # Extract letter from PitchClass at compile time
    start_letter = letter(PC)
    
    # Calculate target letter
    letter_steps = N - 1
    start_pos = letter_position(start_letter)
    new_letter_pos = mod(start_pos + letter_steps, 7)
    
    letters = [C, D, E, F, G, A, B]
    target_letter = letters[new_letter_pos + 1]
    
    # Calculate semitones
    start_semi = semitone(PC)
    interval_semi = semitones(Interval{N, Q})
    total_semi = start_semi + interval_semi
    
    # Calculate octave changes
    octave_from_letters = div(start_pos + letter_steps, 7)
    new_octave = Oct + octave_from_letters
    
    # Determine required accidental
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
    new_pc = PitchClass{target_letter, new_acc}
    
    :(Pitch{$new_pc, $new_octave}())
end

# Add interval to pitch instance
Base.:+(p::Pitch, i::Type{<:Interval}) = typeof(p) + i

# Subtract interval (go down)
@generated function Base.:-(::Type{Pitch{PC, Oct}}, ::Type{Interval{N, Q}}) where {PC, Oct, N, Q}
    # Similar to addition but in reverse
    # ... implementation
    :(Pitch{PC, Oct}())  # Placeholder
end

# ============= Common Intervals =============

const P1 = Interval{1, Perfect}
const m2 = Interval{2, Minor}
const M2 = Interval{2, Major}
const m3 = Interval{3, Minor}
const M3 = Interval{3, Major}
const P4 = Interval{4, Perfect}
const A4 = Interval{4, Augmented}
const d5 = Interval{5, Diminished}
const P5 = Interval{5, Perfect}
const m6 = Interval{6, Minor}
const M6 = Interval{6, Major}
const m7 = Interval{7, Minor}
const M7 = Interval{7, Major}
const P8 = Interval{8, Perfect}

# ============= Interval Arithmetic =============

# Add two intervals
@generated function Base.:+(::Type{Interval{N1, Q1}}, ::Type{Interval{N2, Q2}}) where {N1, Q1, N2, Q2}
    # Use a reference pitch to calculate
    # C4 + interval1 + interval2
    # Then extract the total interval
    # ... implementation
    :(Interval{1, Perfect}())  # Placeholder
end

# Invert an interval
@generated function invert(::Type{Interval{N, Q}}) where {N, Q}
    # P5 inverts to P4, M3 inverts to m6, etc.
    new_number = 9 - N
    
    # Quality transformation for inversion
    if Q == Major
        new_quality = Minor
    elseif Q == Minor
        new_quality = Major
    elseif Q == Augmented
        new_quality = Diminished
    elseif Q == Diminished
        new_quality = Augmented
    else  # Perfect stays Perfect
        new_quality = Perfect
    end
    
    :(Interval{$new_number, $new_quality}())
end
