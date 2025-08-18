using RealtimeMusicTheory
using BenchmarkTools
using Test

import RealtimeMusicTheory: semitones, offset, number

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
		@test number(Pitch(C, 4)) == 60  # middle C
		@test number(Pitch(A, 4)) == 69  # A440
		all_pitch_numbers = vec([number(Pitch(pc, reg)) for pc in canonical_pitch_classes, reg in -1:8])
		@test all_pitch_numbers == 0:119
		
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
			# adjacent elements should always be 5 semitones apart from each other:
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
			# generic equivalence at distance 7:
			for i in -24:24
				a = PitchClass(LineOfFifths, i - 7)
				b = PitchClass(LineOfFifths, i)
				c = PitchClass(LineOfFifths, i + 7)
				@test GPC(a) == GPC(b) == GPC(c)
			end
			# enharmonic equivalence at distance 12:
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
		for l in letters
			for n in 1:14
				expected_distance = (n - 1) % length(LetterSpace)
				@test distance(LetterSpace, Clockwise, l, l + GenericInterval(n)) == expected_distance
				# for PitchClass, sharpening of flattening should not change generic distance:
				for acc in -3:3
					pc = PitchClass(l, acc)
					@test distance(LetterSpace, Clockwise, pc, pc + GenericInterval(n)) == expected_distance
				end
			end
		end

		# test equivalence of interval semitone size as found in Wikipedia table of simple intervals
		@test semitones(Interval(1, Perfect)) == semitones(Interval(2, Diminished))
		@test semitones(Interval(2, Minor)) == semitones(Interval(1, Augmented))
		@test semitones(Interval(2, Major)) == semitones(Interval(3, Diminished))
		@test semitones(Interval(3, Minor)) == semitones(Interval(2, Augmented))
		@test semitones(Interval(3, Major)) == semitones(Interval(4, Diminished))
		@test semitones(Interval(4, Perfect)) == semitones(Interval(3, Augmented))
		@test semitones(Interval(5, Perfect)) == semitones(Interval(6, Diminished))
		@test semitones(Interval(5, Diminished)) == semitones(Interval(4, Augmented))
		@test semitones(Interval(6, Minor)) == semitones(Interval(5, Augmented))
		@test semitones(Interval(6, Major)) == semitones(Interval(7, Diminished))
		@test semitones(Interval(7, Minor)) == semitones(Interval(6, Augmented))
		@test semitones(Interval(7, Major)) == semitones(Interval(8, Diminished))
		@test semitones(Interval(8, Perfect)) == semitones(Interval(7, Augmented))

		# test proper spellings
		@test C♮ + Interval(3, Major) == E♮
		@test C♮ + Interval(3, Minor) == E♭
		@test C♮ + Interval(5, Perfect) == G♮
		@test C♮ + Interval(5, Diminished) == G♭
		@test C♮ + Interval(5, Augmented) == G♯
		@test F♯ + Interval(4, Perfect) == B♮
		@test F♯ + Interval(4, Augmented) == B♯
		@test A♮ + Interval(7, Minor) == G♮
		@test A♮ + Interval(7, Diminished) == G♭
		@test E♭ + Interval(6, Major) == C♮
		@test E♭ + Interval(6, Diminished) == C𝄫
		@test C♯ + Interval(7, Diminished) == B♭
		@test G♮ + Interval(2, Major) == A♮
		@test G♮ + Interval(2, Minor) == A♭
		@test F♮ + Interval(4, Perfect) == B♭
		@test F♮ + Interval(4, Augmented) == B♮
		@test D♮ + Interval(2, Minor) == E♭
		@test D♮ + Interval(2, Major) == E♮
		@test B♮ + Interval(8, Augmented) == B♯

		# test inference of intervals between two pitches
		for r in 0:3
			@test Interval(Pitch(C♮, 4), Pitch(E♮, 4 + r)) == Interval(3 + 7r, Major)
			@test Interval(Pitch(C♮, 4), Pitch(E♭, 4 + r)) == Interval(3 + 7r, Minor)
			@test Interval(Pitch(C♮, 4), Pitch(G♮, 4 + r)) == Interval(5 + 7r, Perfect)
			@test Interval(Pitch(C♮, 4), Pitch(G♭, 4 + r)) == Interval(5 + 7r, Diminished)
			@test Interval(Pitch(C♮, 4), Pitch(G♯, 4 + r)) == Interval(5 + 7r, Augmented)
			@test Interval(Pitch(F♯, 4), Pitch(B♮, 4 + r)) == Interval(4 + 7r, Perfect)
			@test Interval(Pitch(F♯, 4), Pitch(B♯, 4 + r)) == Interval(4 + 7r, Augmented)
			@test Interval(Pitch(A♮, 4), Pitch(G♮, 5 + r)) == Interval(7 + 7r, Minor)
			@test Interval(Pitch(A♮, 4), Pitch(G♭, 5 + r)) == Interval(7 + 7r, Diminished)
			@test Interval(Pitch(E♭, 4), Pitch(C♮, 5 + r)) == Interval(6 + 7r, Major)
			@test Interval(Pitch(E♭, 4), Pitch(C𝄫, 5 + r)) == Interval(6 + 7r, Diminished)
			@test Interval(Pitch(C♯, 4), Pitch(B♭, 4 + r)) == Interval(7 + 7r, Diminished)
			@test Interval(Pitch(G♮, 4), Pitch(A♮, 4 + r)) == Interval(2 + 7r, Major)
			@test Interval(Pitch(G♮, 4), Pitch(A♭, 4 + r)) == Interval(2 + 7r, Minor)
			@test Interval(Pitch(F♮, 4), Pitch(B♭, 4 + r)) == Interval(4 + 7r, Perfect)
			@test Interval(Pitch(F♮, 4), Pitch(B♮, 4 + r)) == Interval(4 + 7r, Augmented)
			@test Interval(Pitch(D♮, 4), Pitch(E♭, 4 + r)) == Interval(2 + 7r, Minor)
			@test Interval(Pitch(D♮, 4), Pitch(E♮, 4 + r)) == Interval(2 + 7r, Major)
			@test Interval(Pitch(B♮, 4), Pitch(B♯, 5 + r)) == Interval(8 + 7r, Augmented)
		end

		# for any pitch, adding a unison will not change the register; 
		# adding an octave (or two) will
		for l in letters
			for reg in 0:7
				for acc in -3:3
					p1 = Pitch(l, Accidental(acc), reg)
					@test register(p1 + P1) == reg
					@test register(p1 + P8) == reg + 1
					@test register(p1 + Interval(15, Perfect)) == reg + 2
				end
			end
		end

		# registers begin at C; so, for C in any register, adding
		# an interval less than an octave should not result in register change
		for reg in 0:7
			p1 = Pitch(C, reg)
			for n in [2, 3, 6, 7]
				for quality in [Minor, Major, Diminished, Augmented]
					@test register(p1 + Interval(n, quality)) == reg
				end
			end
			for n in [1, 4, 5]
				for quality in [Perfect, Diminished, Augmented]
					@test register(p1 + Interval(n, quality)) == reg
				end
			end
		end
	end
end

