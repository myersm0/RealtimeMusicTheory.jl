
abstract type Step end
abstract type SimpleStep <: Step end
abstract type MusicalStep <: Step end

# Chromatic steps (semitones)
struct ChromaticStep{N} <: SimpleStep end
ChromaticStep(n) = ChromaticStep{n}

# Diatonic steps (letter names)
struct DiatonicStep{N} <: SimpleStep end
DiatonicStep(n) = DiatonicStep{n}

abstract type IntervalQuality end
struct Perfect <: IntervalQuality end
struct Major <: IntervalQuality end
struct Minor <: IntervalQuality end
struct Augmented <: IntervalQuality end
struct Diminished <: IntervalQuality end

# Generic interval (will be defined as scale steps)
struct GenericInterval{N} <: MusicalStep end
GenericInterval(n) = GenericInterval{n}

struct SpecificInterval{Number, Quality <: IntervalQuality} <: MusicalStep end

function SpecificInterval(n::Int, quality::Type{Q}) where Q <: IntervalQuality
	# validate interval/quality combination
	simple = mod1(n, 7)
	(Q == Perfect && !(simple in [1, 4, 5])) && error("Perfect quality only valid for unison, 4th, 5th, and octave")
	(Q in [Major, Minor] && !(simple in [2, 3, 6, 7])) && error("Major/minor quality only valid for 2nd, 3rd, 6th, 7th")
	return SpecificInterval{n, Q}
end

# Common aliases
const Semitone = ChromaticStep{1}
const WholeTone = ChromaticStep{2}
const Interval = SpecificInterval
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

@generated function ChromaticStep(::Type{Interval{N, Q}}) where {N, Q}
	# Handle compound intervals by reducing to simple interval + octaves
	octaves = div(N - 1, 7)
	simple_interval = mod1(N, 7)
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
	)
	# For octave (8), handle separately
	if simple_interval == 1 && N > 1  # it's an 8, 15, 22, etc.
		base_semi = Q == Perfect ? 0 : Q == Augmented ? 1 : Q == Diminished ? -1 : 0
	else
		base_semi = get(table, (simple_interval, Q), 0)
	end
	total_semi = base_semi + (octaves * 12)
	return :(ChromaticStep{$total_semi})
end

