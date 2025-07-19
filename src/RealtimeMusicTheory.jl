module RealtimeMusicTheory

export Pitch, C, D, E, F, G, A, B
export Natural, Sharp, Flat, DoubleSharp, DoubleFlat, ♮, ♯, ♭, ♯♯, ♭♭
export Interval, Unison, MinorSecond, MajorSecond, MinorThird, MajorThird
export PerfectFourth, PerfectFifth, MinorSixth, MajorSixth
export MinorSeventh, MajorSeventh, Octave
export Scale, degree, MajorScale, NaturalMinorScale
export Chord, majortriad, minortriad
export semitone, semitones, offset, next_note, scale_interval, degree
export majortriad, minortriad, is_major_triad, frequency
export EqualTemperament

# ===== Core Types =====

abstract type PitchClass end
struct C <: PitchClass end
struct D <: PitchClass end
struct E <: PitchClass end
struct F <: PitchClass end
struct G <: PitchClass end
struct A <: PitchClass end
struct B <: PitchClass end

abstract type Accidental end
struct Natural <: Accidental end
struct Sharp <: Accidental end
struct Flat <: Accidental end
struct DoubleSharp <: Accidental end
struct DoubleFlat <: Accidental end

const ♮ = Natural
const ♯ = Sharp
const ♭ = Flat
const ♯♯ = DoubleSharp
const ♭♭ = DoubleFlat

# ===== Compile-time tables =====

# Base semitones for natural notes
semitone(::Type{C}) = 0
semitone(::Type{D}) = 2
semitone(::Type{E}) = 4
semitone(::Type{F}) = 5
semitone(::Type{G}) = 7
semitone(::Type{A}) = 9
semitone(::Type{B}) = 11

# Accidental modifications
offset(::Type{Natural}) = 0
offset(::Type{Sharp}) = 1
offset(::Type{Flat}) = -1
offset(::Type{DoubleSharp}) = 2
offset(::Type{DoubleFlat}) = -2

# Note succession (for scales)
next_note(::Type{C}) = D
next_note(::Type{D}) = E
next_note(::Type{E}) = F
next_note(::Type{F}) = G
next_note(::Type{G}) = A
next_note(::Type{A}) = B
next_note(::Type{B}) = C

# ===== Pitch =====

struct Pitch{PC <: PitchClass, Acc <: Accidental, Oct} end

Pitch(::Type{PC}, ::Type{Acc}, octave::Int) where {PC <: PitchClass, Acc <: Accidental} = 
	Pitch{PC, Acc, octave}()

Pitch(::Type{PC}, octave::Int) where {PC <: PitchClass} = 
	Pitch{PC, Natural, octave}()

# Total semitones from C0
semitone(::Pitch{PC, Acc, Oct}) where {PC, Acc, Oct} = 
	semitone(PC) + offset(Acc) + 12 * Oct

Base.show(io::IO, ::Pitch{PC, Acc, Oct}) where {PC, Acc, Oct} = 
	print(io, PC, Acc == Natural ? "" : Acc == Sharp ? "♯" : "♭", Oct)

# ===== Intervals =====

struct Interval{Semitones} end

# Constructors for common intervals
const Unison = Interval{0}
const MinorSecond = Interval{1}
const MajorSecond = Interval{2}
const MinorThird = Interval{3}
const MajorThird = Interval{4}
const PerfectFourth = Interval{5}
const Tritone = Interval{6}
const PerfectFifth = Interval{7}
const MinorSixth = Interval{8}
const MajorSixth = Interval{9}
const MinorSeventh = Interval{10}
const MajorSeventh = Interval{11}
const Octave = Interval{12}

semitones(::Type{Interval{S}}) where S = S

# ===== Pitch arithmetic =====

@generated function Base.:+(::Pitch{PC, Acc, Oct}, ::Type{Interval{S}}) where {PC, Acc, Oct, S}
	start_semi = semitone(PC) + offset(Acc)
	total_semi = start_semi + S
	
	new_octave = Oct + div(total_semi, 12)
	remainder = mod(total_semi, 12)
	
	# Map remainder back to pitch class and accidental
	# (todo: will need more sophisticated implementation)
	pc_map = Dict(
		0 => (C, Natural),
		1 => (C, Sharp),
		2 => (D, Natural),
		3 => (D, Sharp),
		4 => (E, Natural),
		5 => (F, Natural),
		6 => (F, Sharp),
		7 => (G, Natural),
		8 => (G, Sharp),
		9 => (A, Natural),
		10 => (A, Sharp),
		11 => (B, Natural)
	)
	
	new_pc, new_acc = pc_map[remainder]
	
	# Return the expression that creates the new pitch
	:(Pitch{$new_pc, $new_acc, $new_octave}())
end

# Convenience: allow adding interval instances
Base.:+(p::Pitch, ::Interval{S}) where S = p + Interval{S}

# ===== Scales =====

abstract type ScalePattern end
struct MajorScale <: ScalePattern end
struct NaturalMinorScale <: ScalePattern end
struct HarmonicMinorScale <: ScalePattern end

scale_intervals(::Type{MajorScale}) = (
	MajorSecond, MajorSecond, MinorSecond,
	MajorSecond, MajorSecond, MajorSecond, MinorSecond
)

scale_intervals(::Type{NaturalMinorScale}) = (
	MajorSecond, MinorSecond, MajorSecond,
	MajorSecond, MinorSecond, MajorSecond, MajorSecond
)

struct Scale{Tonic <: Pitch, Pattern <: ScalePattern} end

Scale(tonic::T, ::Type{P}) where {T <: Pitch, P <: ScalePattern} = Scale{T, P}()

@generated function degree(::Scale{Tonic, Pattern}, ::Val{N}) where {Tonic, Pattern, N}
	intervals = scale_intervals(Pattern)
	# calculate the pitch by adding intervals
	pitch_expr = :(Tonic())
	for i in 1:(N-1)
		interval = intervals[mod1(i, length(intervals))]
		pitch_expr = :($pitch_expr + $interval)
	end
	return pitch_expr
end

Base.getindex(s::Scale, n::Int) = degree(s, Val(n))

# ===== Chords =====

struct Chord{Pitches <: Tuple} end

Chord(pitches::Pitch...) = Chord{typeof(pitches)}()

majortriad(root::P) where P <: Pitch = Chord(root, root + MajorThird, root + PerfectFifth)
minortriad(root::P) where P <: Pitch = Chord(root, root + MinorThird, root + PerfectFifth)

is_major_triad(::Type{Chord{Tuple{R, T, F}}}) where {R, T, F} = 
	T == typeof(R() + MajorThird) && F == typeof(R() + PerfectFifth)

# ===== Temperaments =====

struct EqualTemperament{BasePitch <: Pitch, BaseFreq} end

EqualTemperament(p::P, freq::Float64) where P <: Pitch = 
	EqualTemperament{P, freq}()

EqualTemperament(p::P, freq::Number) where P <: Pitch = 
	EqualTemperament{P, Float64(freq)}()

@generated function frequency(::EqualTemperament{Base, Freq}, ::P) where {Base, Freq, P <: Pitch}
	semi_diff = semitone(P()) - semitone(Base())
	ratio = 2.0^(semi_diff / 12.0)
	:($Freq * $ratio)
end

end
