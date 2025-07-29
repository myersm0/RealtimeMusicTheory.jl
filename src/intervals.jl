
abstract type IntervalQuality end
struct Perfect <: IntervalQuality end
struct Major <: IntervalQuality end
struct Minor <: IntervalQuality end
struct Augmented <: IntervalQuality end
struct Diminished <: IntervalQuality end

struct Interval{Number, Quality <: IntervalQuality} <: MusicalStep end

Interval(n::Int, quality::Type{Q}) where Q <: IntervalQuality = Interval{n, quality}

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

@generated function to_chromatic_step(::Type{Interval{N, Q}}) where {N, Q}
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

