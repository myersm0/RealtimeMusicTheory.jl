using RealtimeMusicTheory
using BenchmarkTools
using Test

import RealtimeMusicTheory: semitone, offset, number

# todo: add iteration/enumeration of spaces so that we don't have to define this manually
letters = [C, D, E, F, G, A, B]
canonical_pitch_classes = [C♮, C♯, D♮, D♯, E♮, F♮, F♯, G♮, G♯, A♮, A♯, B♮]
enharmonic_variants = [
	C♭, C𝄫, C𝄪,
	D♭, D𝄫, D𝄪,
	E♭, E𝄫, E♯, E𝄪,
	F♭, F𝄫, F𝄪,
	G♭, G𝄫, G𝄪,
	A♭, A𝄫, A𝄪,
	B♭, B𝄫, B♯, B𝄪
]
registers = 1:6

@testset "RealtimeMusicTheory.jl" begin

	@testset "Pitches" begin
		@testset "Basic pitch construction" begin
			@test C♮ == PitchClass(C, Natural)
			@test C♯ == PitchClass(C, Sharp)
			@test D♭ == PitchClass(D, Flat)
			middle_c = Pitch(C, Natural, 4)
			@test middle_c == Pitch(C, 4)
			@test register(middle_c) == 4
			@test letter(middle_c) == C
			@test accidental(middle_c) == Natural
		end
		
		@testset "Accidental offsets" begin
			@test offset(Natural) == 0
			@test offset(Sharp) == 1
			@test offset(Flat) == -1
			@test offset(DoubleSharp) == 2
			@test offset(DoubleFlat) == -2
		end
		
		@testset "Generic pitch classes" begin
			for letter in letters
				for acc in -3:3
					@test GenericPitchClass(PitchClass(letter, acc)) == PitchClass(letter)
				end
			end
		end
	end

	@testset "Spaces" begin
		@test [number(pc) for pc in canonical_pitch_classes] == collect(0:length(LetterSpace) - 1)

		@test number(Pitch(C, 4)) == 60  # middle C
		@test number(Pitch(A, 4)) == 69  # A440
		@test number(Pitch(C, -1)) == 0  # lowest MIDI note
		
		@testset "LetterSpace (Generic, Circular)" begin
			test_nums = collect(0:length(LetterSpace) - 1)
			@test [number(l) for l in letters] == test_nums
			for acc in -2:2
				@test [number(LetterSpace, PitchClass(l, acc)) for l in letters] == test_nums
			end
			@test [LetterName(LetterSpace, n) for n in test_nums] == letters

			for i in 1:7
				for j in 1:7
					d = mod(j - i, 7)
					d > 3 && (d -= 7)
					@test distance(LetterSpace, letters[i], letters[j]) == abs(d)
					@test distance(LetterSpace, letters[j], letters[i]) == abs(d)
					@test direction(LetterSpace, letters[i], letters[j]) == (d < 0 ? Counterclockwise : Clockwise)
					@test direction(LetterSpace, letters[j], letters[i]) == (d <= 0 ? Clockwise : Counterclockwise)
				end
			end
		end
		
		@testset "GenericFifthsSpace" begin
			test_nums = [0, 2, 4, 6, 1, 3, 5]
			@test [number(GenericFifthsSpace, l) for l in letters] == test_nums
			for acc in -2:2
				@test [number(GenericFifthsSpace, PitchClass(l, acc)) for l in letters] == test_nums
			end
			@test [LetterName(GenericFifthsSpace, n) for n in test_nums] == letters
			# todo: add tests of distance and direction
		end
		
		@testset "GenericThirdsSpace" begin
			test_nums = [0, 4, 1, 5, 2, 6, 3]
			@test [number(GenericThirdsSpace, l) for l in letters] == test_nums
			for acc in -2:2
				@test [number(GenericThirdsSpace, PitchClass(l, acc)) for l in letters] == test_nums
			end
			@test [LetterName(GenericThirdsSpace, n) for n in test_nums] == letters
			# todo: add tests of distance and direction
		end
		
		@testset "Adjacent in exactly one space" begin
			# every pair of letters should be adjacent in exactly one generic space
			for i in 1:7, j in i+1:7
				l1, l2 = letters[i], letters[j]
				adjacencies = [
					distance(LetterSpace, l1, l2) == 1,
					distance(GenericFifthsSpace, l1, l2) == 1,
					distance(GenericThirdsSpace, l1, l2) == 1
				]
				@test sum(adjacencies) == 1
			end
		end
		
		@testset "PitchClassSpace (Chromatic)" begin
			test_nums = 0:11
			@test [number(PitchClassSpace, pc) for pc in canonical_pitch_classes] == test_nums
			# todo: test variant spellings
			@test distance(PitchClassSpace, C♮, B♮) == 1  # Wraparound
			@test distance(PitchClassSpace, C♮, F♯) == 6  # Tritone
		end
		
		@testset "LineOfFifths (Linear, Infinite)" begin
			@test Base.isfinite(LineOfFifths) == false
			@test TopologyStyle(LineOfFifths) == Linear
			@test_throws ErrorException Base.size(LineOfFifths)
			# adjacent elements should always be 5 semitones apart from each other
			for i in -24:24
				a = PitchClass(LineOfFifths, i - 1)
				b = PitchClass(LineOfFifths, i)
				c = PitchClass(LineOfFifths, i + 1)
				@test distance(PitchClassSpace, a, b) == 5
				@test distance(PitchClassSpace, b, a) == 5
				@test distance(PitchClassSpace, b, c) == 5
				@test distance(PitchClassSpace, c, b) == 5
				@test direction(LineOfFifths, a, b) == Right
				@test direction(LineOfFifths, b, a) == Left
				@test direction(LineOfFifths, b, c) == Right
				@test direction(LineOfFifths, c, b) == Left
			end
			# generic equivalence at distance 7
			for i in -24:24
				a = PitchClass(LineOfFifths, i - 7)
				b = PitchClass(LineOfFifths, i)
				c = PitchClass(LineOfFifths, i + 7)
				@test GPC(a) == GPC(b) == GPC(c)
			end
			# enharmonic equivalence at distance 12
			for i in -24:24
				a = PitchClass(LineOfFifths, i - 12)
				b = PitchClass(LineOfFifths, i)
				c = PitchClass(LineOfFifths, i + 12)
				@test is_enharmonic(a, b)
				@test is_enharmonic(b, a)
				@test is_enharmonic(b, c)
				@test is_enharmonic(c, b)
				@test is_enharmonic(a, c)
				@test is_enharmonic(c, a)
			end
		end
		
		# todo: make this more comprehensive; e.g. modeled on the above
		@testset "CircleOfFifths" begin
			@test Base.size(CircleOfFifths) == 12
			@test TopologyStyle(CircleOfFifths) == Circular
			@test number(CircleOfFifths, C♮) == 0
			@test number(CircleOfFifths, G♮) == 1
			@test number(CircleOfFifths, F♮) == 11  # Wraps around
			@test distance(CircleOfFifths, C♮, G♮) == 1
			@test distance(CircleOfFifths, C♮, F♮) == 1  # Other direction
			@test distance(CircleOfFifths, C♮, F♯) == 6  # Opposite side
		end

		# todo: test indexing of other spaces in this way
		@testset "MusicalSpace indexing" begin
			# all the canonical pitches in CircleOfFifths order; 12 diff ways of specifying the same thing:
			test_ranges = [
				CircleOfFifths(0, 12) |> collect,
				CircleOfFifths(C♮, 12) |> collect,
				CircleOfFifths(G♮ - 1, 12) |> collect,
				CircleOfFifths(F♮ + 1, 12) |> collect,
				CircleOfFifths(C♮, F♮) |> collect,
				CircleOfFifths(C♮, A♯ + 1) |> collect,
				CircleOfFifths(C♮, C♮ - 1) |> collect,
				CircleOfFifths(C♮, 13, 12) |> collect,
				CircleOfFifths(F♮, -1, 12) |> collect |> reverse,
				CircleOfFifths(F♮, -13, 12) |> collect |> reverse,
				Iterators.take(CircleOfFifths(0, 24), 12) |> collect,
				Iterators.drop(CircleOfFifths(0, 24), 12) |> collect,
			]
			@test allequal(test_ranges)
		end

	end

	@testset "Interval arithmetic" begin
		c4 = Pitch(C, 4)

		@test C + GenericInterval(1) == D
		@test C + GenericInterval(-1) == B
		@test C - GenericInterval(1) == B

		@test C♮ + GenericInterval(1) == D

		semitones(P1)
		semitones(m3)
		semitones(P8)

		@test (c4 + ChromaticStep{1}) == Pitch(C, Sharp, 4)
		@test (c4 + ChromaticStep{12}) == Pitch(C, 5)

		@test (c4 + DiatonicStep{1}) == Pitch(D, 4)
		@test (c4 + DiatonicStep{7}) == Pitch(C, 5)
		
		@test (c4 + P1) == c4
		@test (c4 + M3) == Pitch(E, Natural, 4)
		@test (c4 + P5) == Pitch(G, Natural, 4)
		@test (c4 + P8) == Pitch(C, Natural, 5)
		
		# Intervals with accidentals
		@test (c4 + m2) == Pitch(D, Flat, 4)
		@test (c4 + m3) == Pitch(E, Flat, 4)
		
		# Octave crossing
		b4 = Pitch(B, 4)
		@test (b4 + M2) == Pitch(C, Sharp, 5)
		
		# From different starting notes
		d4 = Pitch(D, 4)
		@test (d4 + M3) == Pitch(F, Sharp, 4)
		
		e4 = Pitch(E, 4)
		@test (e4 + P4) == Pitch(A, Natural, 4)
		
		# With accidentals in starting pitch
		f_sharp = Pitch(F, ♯, 4)
		@test semitone(f_sharp + P5) == semitone(Pitch(C, ♯, 5))
	end
	
	@testset "Scales" begin
		c_major = Scale(MajorScale, PitchClass(C))
		@test c_major[ScaleDegree{1}] == PitchClass(C, Natural)
		@test c_major[ScaleDegree{2}] == PitchClass(D, Natural)
		@test c_major[ScaleDegree{3}] == PitchClass(E, Natural)
		@test c_major[ScaleDegree{4}] == PitchClass(F, Natural)
		@test c_major[ScaleDegree{5}] == PitchClass(G, Natural)
		@test c_major[ScaleDegree{6}] == PitchClass(A, Natural)
		@test c_major[ScaleDegree{7}] == PitchClass(B, Natural)
		@test c_major[ScaleDegree{8}] == PitchClass(C, Natural)

		d_minor = Scale(MinorScale, PitchClass(D)) # todo: this gives us A# instead of Bb
		@test d_minor[ScaleDegree{1}] == PitchClass(D, Natural)
		@test d_minor[ScaleDegree{2}] == PitchClass(E, Natural)
		@test d_minor[ScaleDegree{3}] == PitchClass(F, Natural)
		@test d_minor[ScaleDegree{4}] == PitchClass(G, Natural)
		@test d_minor[ScaleDegree{5}] == PitchClass(A, Natural)
		@test d_minor[ScaleDegree{6}] == PitchClass(B, Flat)
		@test d_minor[ScaleDegree{7}] == PitchClass(C, Natural)
		@test d_minor[ScaleDegree{8}] == PitchClass(D, Natural)
	end
	
	@testset "Chords" begin
		c_major = Scale(MajorScale, PitchClass(C))
		c_triad = triad(c_major, ScaleDegree{1})
		c_triad == Chord{Tuple{PitchClass(C), PitchClass(E), PitchClass(G)}}
		d_minor = Scale(MinorScale, PitchClass(D))
		d_triad = triad(d_minor, ScaleDegree{1})
		d_triad == Chord{Tuple{PitchClass(D), PitchClass(F), PitchClass(A)}}
	end
	
	@testset "Type stability" begin
		c = Pitch(C, 4)
		@test (@inferred c + M3) == Pitch(E, Natural, 4)
		@test @allocated(c + M3) == 0
		@test (@inferred semitone(c)) == 60
		@test @allocated(semitone(c)) == 0
	end
	
	@testset "Edge cases" begin
		# Very high/low octaves
		c_neg1 = Pitch(C, -1)
		@test semitone(c_neg1) == 0  # MIDI note 0
		
		c10 = Pitch(C, 10)
		@test semitone(c10) == 132
		
		# Enharmonic equivalents have same semitone value
		c_sharp = Pitch(C, ♯, 4)
		d_flat = Pitch(D, ♭, 4)
		@test semitone(c_sharp) == semitone(d_flat)
		
		# Intervals that wrap around
		b4 = Pitch(B, 4)
		@test semitone(b4 + m2) == semitone(Pitch(C, 5))
	end
	
	@testset "Performance benchmarks" begin
		c = Pitch(C, 4)
		
		# These should be essentially free
		b_pitch_creation = @benchmark Pitch(C, 4)
		@test median(b_pitch_creation.times) < 10  # nanoseconds
		
		b_interval_add = @benchmark Pitch(C, 4) + M3
		@test median(b_interval_add.times) < 10
		
		b_semitone = @benchmark semitone(Pitch(C, 4))
		@test median(b_semitone.times) < 10

		b_scale_creation = @benchmark Scale(MajorScale, PitchClass(C))
		@test median(b_scale_creation.times) < 10
		
		# No allocations
		@test b_pitch_creation.allocs == 0
		@test b_interval_add.allocs == 0
		@test b_semitone.allocs == 0
		@test b_scale_creation.allocs == 0
	end
end

