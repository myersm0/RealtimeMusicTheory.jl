using RealtimeMusicTheory
using BenchmarkTools
using Test

import RealtimeMusicTheory: semitone, offset, number

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
		
		@testset "Semitone calculations" begin
			@test semitone(C♮) == 0
			@test semitone(D♮) == 2
			@test semitone(E♮) == 4
			@test semitone(F♮) == 5
			@test semitone(G♮) == 7
			@test semitone(A♮) == 9
			@test semitone(B♮) == 11
			
			@test semitone(C♯) == 1
			@test semitone(D♭) == 1
			@test semitone(F♯) == 6
			@test semitone(G♭) == 6
			
			# MIDI numbers
			@test semitone(Pitch(C, 4)) == 60  # Middle C
			@test semitone(Pitch(A, 4)) == 69  # A440
			@test semitone(Pitch(C, -1)) == 0  # lowest MIDI note
		end
		
		@testset "Generic pitch classes" begin
			@test GenericPitchClass(C♯) == C♮
			@test GenericPitchClass(D♭) == D♮
			@test GenericPitchClass(F♯) == F♮
			@test GPC(B♭) == B♮  # Test alias
		end
	end

	@testset "Spaces" begin
		@testset "LetterSpace (Generic, Circular)" begin
			# size and topology
			@test Base.size(LetterSpace) == 7
			@test Base.isfinite(LetterSpace) == true
			@test TopologyStyle(LetterSpace) == Circular
			
			# number mappings
			@test number(LetterSpace, C) == 0
			@test number(LetterSpace, D) == 1
			@test number(LetterSpace, B) == 6
			
			# works with pitch classes (extracts letter)
			@test number(LetterSpace, C♯) == 0
			@test number(LetterSpace, D♭) == 1
			
			# circular distances
			@test distance(LetterSpace, C, D) == 1
			@test distance(LetterSpace, C, B) == 1  # wraparound
			@test distance(LetterSpace, C, F) == 3
			@test distance(LetterSpace, F, C) == 3  # symmetric
			
			# directions
			@test direction(LetterSpace, C, D) == Clockwise
			@test direction(LetterSpace, C, B) == Counterclockwise
			@test direction(LetterSpace, A, C) == Clockwise  # shorter path
		end
		
		@testset "GenericFifthsSpace" begin
			@test number(GenericFifthsSpace, C) == 0
			@test number(GenericFifthsSpace, G) == 1
			@test number(GenericFifthsSpace, D) == 2
			@test number(GenericFifthsSpace, F) == 6
			
			# C and D are adjacent in LetterSpace but not GenericFifthsSpace
			@test distance(LetterSpace, C, D) == 1
			@test distance(GenericFifthsSpace, C, D) == 2
			
			# C and G are adjacent in GenericFifthsSpace but not LetterSpace
			@test distance(GenericFifthsSpace, C, G) == 1
			@test distance(LetterSpace, C, G) == 3
		end
		
		@testset "GenericThirdsSpace" begin
			# verify thirds cycle order
			@test number(GenericThirdsSpace, C) == 0
			@test number(GenericThirdsSpace, E) == 1
			@test number(GenericThirdsSpace, G) == 2
			
			# C and E are adjacent in GenericThirdsSpace
			@test distance(GenericThirdsSpace, C, E) == 1
			@test distance(LetterSpace, C, E) == 2
			@test distance(GenericFifthsSpace, C, E) == 3
		end
		
		@testset "Adjacent in exactly one space" begin
			# Every pair of letters should be adjacent in exactly one generic space
			letters = [C, D, E, F, G, A, B]
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
			@test Base.size(PitchClassSpace) == 12
			@test TopologyStyle(PitchClassSpace) == Circular
			
			# Chromatic numbering
			@test number(PitchClassSpace, C♮) == 0
			@test number(PitchClassSpace, C♯) == 1
			@test number(PitchClassSpace, G♯) == 8
			@test number(PitchClassSpace, B♮) == 11
			
			# Enharmonic equivalents (when implemented)
			# @test number(PitchClassSpace, C♯) == number(PitchClassSpace, D♭)
			
			# circular distance
			@test distance(PitchClassSpace, C♮, B♮) == 1  # Wraparound
			@test distance(PitchClassSpace, C♮, F♯) == 6  # Tritone
		end
		
		@testset "LineOfFifths (Linear, Infinite)" begin
			@test Base.isfinite(LineOfFifths) == false
			@test TopologyStyle(LineOfFifths) == Linear
			@test_throws ErrorException Base.size(LineOfFifths)
			
			# natural notes positions
			@test number(LineOfFifths, F♮) == -3
			@test number(LineOfFifths, C♮) == -2
			@test number(LineOfFifths, G♮) == -1
			@test number(LineOfFifths, D♮) == 0
			
			# sharps and flats
			@test number(LineOfFifths, F♯) == 4   # F + 7
			@test number(LineOfFifths, B♭) == -4  # B(3) - 7
			@test number(LineOfFifths, C♯) == 5   # C(-2) + 7
			
			# generic equivalence at distance 7
			@test distance(LineOfFifths, C♮, C♯) == 7
			@test distance(LineOfFifths, F♮, F♯) == 7
			@test distance(LineOfFifths, B♮, B♭) == 7
			
			# enharmonic equivalence at distance 12
			@test is_enharmonic(C♯, D♭) == true
			@test is_enharmonic(F♯, G♭) == true
			@test is_enharmonic(C♮, C♯) == false
			
			# direction on linear space
			@test direction(LineOfFifths, C♮, G♮) == Right
			@test direction(LineOfFifths, G♮, C♮) == Left
		end
		
		@testset "CircleOfFifths" begin
			@test Base.size(CircleOfFifths) == 12
			@test TopologyStyle(CircleOfFifths) == Circular
			
			# cerify fifths ordering
			@test number(CircleOfFifths, C♮) == 0
			@test number(CircleOfFifths, G♮) == 1
			@test number(CircleOfFifths, F♮) == 11  # Wraps around
			
			# distance around the circle
			@test distance(CircleOfFifths, C♮, G♮) == 1
			@test distance(CircleOfFifths, C♮, F♮) == 1  # Other direction
			@test distance(CircleOfFifths, C♮, F♯) == 6  # Opposite side
		end
		
		@testset "Direction operators" begin
			@test Clockwise * 3 == 3
			@test Counterclockwise * 3 == -3
			@test Left * 5 == -5
			@test Right * 5 == 5
		end
	end

	@testset "Interval arithmetic" begin
		c4 = Pitch(C, 4)

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

