
SUITE["realistic"]["core"] = BenchmarkGroup()

# @noinline to prevent complete optimization
@noinline compute_interval(pc, interval) = pc + interval
@noinline get_number(p) = number(p)

SUITE["realistic"]["core"]["pitch_class"] = @benchmarkable PitchClass(C, Natural)
SUITE["realistic"]["core"]["interval_add"] = @benchmarkable compute_interval(C♮, M3)
SUITE["realistic"]["core"]["pitch_number"] = @benchmarkable get_number(Pitch(C♮, 4))

## Compilation overhead
SUITE["realistic"]["compilation"] = BenchmarkGroup()
all_pitch_classes = (
	C♮, C♯, D♭, D♮, D♯, E♭, E♮, E♯, F♭, F♮, F♯, G♭, G♮, G♯, A♭, A♮, A♯, B♭, B♮, B♯, C♭,
	C𝄫, D𝄫, E𝄫, F𝄫, G𝄫, A𝄫, B𝄫, C𝄪, D𝄪, E𝄪, F𝄪, G𝄪, A𝄪, B𝄪
)

# measure first-call compilation
function measure_compilation_overhead()
	exotic_interval = Interval(11, Augmented)  # Augmented 11th
	times = Float64[]
	for pc in all_pitch_classes[25:30]  # Use rare pitch classes
		t = @elapsed begin
			_ = pc + exotic_interval
		end
		push!(times, t)
	end
	return times
end

SUITE["realistic"]["compilation"]["exotic_combinations"] = @benchmarkable measure_compilation_overhead()

SUITE["realistic"]["compilation"]["method_count"] = @benchmarkable begin
	count = 0
	for m in methods(+, (Type{<:PitchClass}, Type{<:AbstractInterval}))
		count += length(m.specializations)
	end
	count
end


## Type dispatch overhead
SUITE["realistic"]["dispatch"] = BenchmarkGroup()

# homogeneous dispatch (fast - single type)
homogeneous_pitches = tuple([C♮ for _ in 1:20]...)
SUITE["realistic"]["dispatch"]["homogeneous"] = @benchmarkable begin
	total = 0
	for p in $homogeneous_pitches
		total += get_number(p)
	end
	total
end

# small union (2-3 types, should use union splitting)
small_union = tuple(C♮, D♮, E♮, C♮, D♮, E♮, C♮, D♮, E♮, C♮)
SUITE["realistic"]["dispatch"]["small_union"] = @benchmarkable begin
	total = 0
	for p in $small_union
		total += get_number(p)
	end
	total
end

# medium union (5-8 types)
medium_union = tuple(C♮, D♮, E♮, F♮, G♮, A♮, B♮, C♯, C♮, D♮, E♮, F♮, G♮, A♮, B♮, C♯)
SUITE["realistic"]["dispatch"]["medium_union"] = @benchmarkable begin
	total = 0
	for p in $medium_union
		total += get_number(p)
	end
	total
end

# large union (20+ types)
large_union = tuple(all_pitch_classes[1:20]...)
SUITE["realistic"]["dispatch"]["large_union"] = @benchmarkable begin
	total = 0
	for p in $large_union
		total += get_number(p)
	end
	total
end

# dynamic dispatch worst case
function process_mixed_array(arr)
	total = 0
	for p in arr
		total += number(p)
	end
	return total
end
mixed_array = Any[all_pitch_classes[1:20]...]
SUITE["realistic"]["dispatch"]["dynamic_array"] = @benchmarkable process_mixed_array($mixed_array)


## Cache pressure

SUITE["realistic"]["cache"] = BenchmarkGroup()

# many different operations to stress instruction cache
function complex_musical_operation()
	total = 0
	# Use many different pitch classes and intervals
	total += number(C♮ + M3)
	total += number(D♭ + m2)
	total += number(E♮ + P5)
	total += number(F♯ + A4)
	total += number(G♭ + d5)
	total += number(A♮ + M6)
	total += number(B♭ + m7)
	total += number(C♯ + P8)
	total += number(D♮ + M2)
	total += number(E♭ + m3)
	total += number(F♮ + P4)
	total += number(G♮ + M7)
	total += distance(PitchClassSpace, C♮, G♮)
	total += distance(LetterSpace, C, F)
	total += distance(LineOfFifths, D♮, A♮)
	total += distance(CircleOfFifths, E♮, B♮)
	return total
end

SUITE["realistic"]["cache"]["many_specializations"] = @benchmarkable complex_musical_operation()

# repeatedly jump between different specialized methods
random_pitches = tuple([all_pitch_classes[mod1(i * 7, 35)] for i in 1:100]...)
SUITE["realistic"]["cache"]["method_jumping"] = @benchmarkable begin
	total = 0
	for p in $random_pitches
		total += get_number(p)
	end
	total
end


## real-world usage patterns

SUITE["realistic"]["real-world"] = BenchmarkGroup()

# chord progression (uses multiple types)
function analyze_progression()
	# I-vi-IV-V in C major
	c_major = (C♮, C♮ + M3, C♮ + P5)
	a_minor = (A♮, A♮ + m3, A♮ + P5)
	f_major = (F♮, F♮ + M3, F♮ + P5)
	g_major = (G♮, G♮ + M3, G♮ + P5)
	
	# coice leading calculations
	total = 0
	total += distance(PitchClassSpace, c_major[1], a_minor[1])
	total += distance(PitchClassSpace, c_major[2], a_minor[2])
	total += distance(PitchClassSpace, c_major[3], a_minor[3])
	total += distance(PitchClassSpace, a_minor[1], f_major[1])
	total += distance(PitchClassSpace, a_minor[2], f_major[2])
	total += distance(PitchClassSpace, a_minor[3], f_major[3])
	return total
end

SUITE["realistic"]["real-world"]["chord_progression"] = @benchmarkable analyze_progression()

chromatic = tuple(C♮, C♯, D♮, D♯, E♮, F♮, F♯, G♮, G♯, A♮, A♯, B♮)
SUITE["realistic"]["real-world"]["chromatic_scale"] = @benchmarkable begin
	result = []
	for pc in $chromatic
		push!(result, Pitch(pc, 4))
	end
	tuple(result...)
end

# all keys major scales (12 different tonics)
function all_major_scales()
	scales = []
	for tonic in (C♮, G♮, D♮, A♮, E♮, B♮, F♯, C♯, F♮, B♭, E♭, A♭, D♭, G♭)
		scale = (
			tonic,
			tonic + M2,
			tonic + M3,
			tonic + P4,
			tonic + P5,
			tonic + M6,
			tonic + M7,
			tonic + P8
		)
		push!(scales, scale)
	end
	return scales
end

SUITE["realistic"]["real-world"]["all_major_scales"] = @benchmarkable all_major_scales()

# modulation through circle of fifths
function circle_of_fifths_modulation()
	current = C♮
	keys = [current]
	for _ in 1:11
		current = PitchClass(CircleOfFifths, mod(number(CircleOfFifths, current) + 1, 12))
		push!(keys, current)
	end
	return tuple(keys...)
end

SUITE["realistic"]["real-world"]["circle_modulation"] = @benchmarkable circle_of_fifths_modulation()

## Method table size

SUITE["realistic"]["methods"] = BenchmarkGroup()

function count_all_methods()
	counts = Dict{Symbol, Int}()
	for func in [+, -, number, distance, direction, letter, accidental, is_enharmonic]
		counts[Symbol(func)] = length(methods(func))
	end
	return counts
end

SUITE["realistic"]["methods"]["total_count"] = @benchmarkable count_all_methods()

# force generation of many specializations
function generate_specializations()
	count = 0
	for pc in all_pitch_classes[1:10]
		for interval in (P1, M2, M3, P4, P5)
			_ = pc + interval
			count += 1
		end
	end
	return count
end

SUITE["realistic"]["methods"]["generate_specs"] = @benchmarkable generate_specializations()

## Stress tests

SUITE["realistic"]["stress"] = BenchmarkGroup()

# extreme type variety
function stress_type_system()
	results = []
	# Use every pitch class with different intervals
	for (i, pc) in enumerate(all_pitch_classes)
		interval_idx = mod1(i, 14)
		interval = (P1, m2, M2, m3, M3, P4, A4, d5, P5, m6, M6, m7, M7, P8)[interval_idx]
		push!(results, pc + interval)
	end
	# check enharmonics between all pairs (sampling)
	for i in 1:5:35, j in i+1:5:35
		is_enharmonic(all_pitch_classes[i], all_pitch_classes[j])
	end
	return length(results)
end

SUITE["realistic"]["stress"]["type_variety"] = @benchmarkable stress_type_system()

# measure cost of type instability
unstable_array = Any[
	C♮, Pitch(D♮, 4), M3, LetterSpace, "not a pitch", 
	F♯, Pitch(G♮, 5), P5, CircleOfFifths, 42
]

function process_unstable(arr)
	count = 0
	for item in arr
		if isa(item, PitchClass)
			count += number(item)
		elseif isa(item, Pitch)
			count += number(item)
		end
	end
	return count
end

SUITE["realistic"]["stress"]["type_unstable"] = @benchmarkable process_unstable($unstable_array)


## Invalidation sensitivity

SUITE["realistic"]["invalidation"] = BenchmarkGroup()

# define new methods at runtime (simulates extending the package)
function test_invalidation()
	# this would invalidate compiled methods if we actually did it;
	# so just measure the cost of checking method tables
	mt = methods(+, (Type{<:PitchClass}, Type{<:AbstractInterval}))
	count = 0
	for m in mt
		if isdefined(m, :specializations)
			count += 1
		end
	end
	return count
end

SUITE["realistic"]["invalidation"]["method_check"] = @benchmarkable test_invalidation()

