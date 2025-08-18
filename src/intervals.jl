
abstract type IntervalQuality end
struct Perfect <: IntervalQuality end
struct Major <: IntervalQuality end
struct Minor <: IntervalQuality end
struct Augmented <: IntervalQuality end
struct Diminished <: IntervalQuality end

abstract type AbstractInterval end
struct GenericInterval{N} <: AbstractInterval end
struct SpecificInterval{Number, Quality <: IntervalQuality} <: AbstractInterval end

GenericInterval(n) = GenericInterval{n}

function SpecificInterval(n::Int, quality::Type{Q}) where Q <: IntervalQuality
	simple = mod1(n, 7)
	(Q == Perfect && !(simple in [1, 4, 5])) && error("Perfect quality only valid for unison, 4th, 5th, and octave")
	(Q in [Major, Minor] && !(simple in [2, 3, 6, 7])) && error("Major/minor quality only valid for 2nd, 3rd, 6th, 7th")
	return SpecificInterval{n, Q}
end

# note: performance hit when using () instead of {} for these
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

