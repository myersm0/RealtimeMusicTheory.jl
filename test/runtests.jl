using RealtimeMusicTheory
using BenchmarkTools
using Test

import RealtimeMusicTheory.semitone

@testset "RealtimeMusicTheory.jl" begin

	@testset "Pitches" begin
		middle_c = Pitch(C, Natural, 4)
		@test middle_c == Pitch(C, 4)
		c_sharp = Pitch(C, ♯, 4)
		@test c_sharp == Pitch(C, Sharp, 4)
		d_flat = Pitch(D, ♭, 4)
		@test d_flat == Pitch(D, Flat, 4)
		@test semitone(middle_c) == 60  # MIDI middle C
		@test semitone(c_sharp) == 61
		@test semitone(d_flat) == 61
		@test semitone(Pitch(A, 4)) == 69  # A440
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

