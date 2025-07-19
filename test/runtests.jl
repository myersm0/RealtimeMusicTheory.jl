using RealtimeMusicTheory
using BenchmarkTools
using Test

@testset "RealtimeMusicTheory.jl" begin

	@testset "PitchClasses" begin
		@test semitone(C) == 0
		@test semitone(D) == 2
		@test semitone(E) == 4
		@test semitone(F) == 5
		@test semitone(G) == 7
		@test semitone(A) == 9
		@test semitone(B) == 11
		@test next_note(C) == D
		@test next_note(B) == C  # Wraps around
	end
	
	@testset "Accidentals" begin
		@test offset(Natural) == 0
		@test offset(Sharp) == 1
		@test offset(Flat) == -1
		@test Natural == ♮
		@test Sharp == ♯
		@test Flat == ♭
	end
	
	@testset "Pitches" begin
		middle_c = Pitch(C, 4)
		@test middle_c isa Pitch{C, Natural, 4}
		c_sharp = Pitch(C, ♯, 4)
		@test c_sharp isa Pitch{C, Sharp, 4}
		d_flat = Pitch(D, ♭, 4)
		@test d_flat isa Pitch{D, Flat, 4}
		@test semitone(middle_c) == 60  # MIDI middle C
		@test semitone(c_sharp) == 61
		@test semitone(d_flat) == 61
		@test semitone(Pitch(A, 4)) == 69  # A440
	end
	
	@testset "Intervals" begin
		@test semitones(Unison) == 0
		@test semitones(MinorSecond) == 1
		@test semitones(MajorSecond) == 2
		@test semitones(MinorThird) == 3
		@test semitones(MajorThird) == 4
		@test semitones(PerfectFourth) == 5
		@test semitones(Tritone) == 6
		@test semitones(PerfectFifth) == 7
		@test semitones(MinorSixth) == 8
		@test semitones(MajorSixth) == 9
		@test semitones(MinorSeventh) == 10
		@test semitones(MajorSeventh) == 11
		@test semitones(Octave) == 12
	end
	
	@testset "Interval arithmetic" begin
		c4 = Pitch(C, 4)
		
		# Basic intervals
		@test (c4 + Unison) == c4
		@test (c4 + MajorThird) isa Pitch{E, Natural, 4}
		@test (c4 + PerfectFifth) isa Pitch{G, Natural, 4}
		@test (c4 + Octave) isa Pitch{C, Natural, 5}
		
		# Intervals with accidentals
		@test (c4 + MinorSecond) isa Pitch{C, Sharp, 4}  # Simplified mapping
		@test (c4 + MinorThird) isa Pitch{D, Sharp, 4}   # Simplified (should be Eb)
		
		# Octave crossing
		b4 = Pitch(B, 4)
		@test (b4 + MajorSecond) isa Pitch{C, Sharp, 5}  # Crosses octave
		
		# From different starting notes
		d4 = Pitch(D, 4)
		@test (d4 + MajorThird) isa Pitch{F, Sharp, 4}
		
		e4 = Pitch(E, 4)
		@test (e4 + PerfectFourth) isa Pitch{A, Natural, 4}
		
		# With accidentals in starting pitch
		f_sharp = Pitch(F, ♯, 4)
		@test semitone(f_sharp + PerfectFifth) == semitone(Pitch(C, ♯, 5))
	end
	
	@testset "Scales" begin
		c_major = Scale(Pitch(C, 4), MajorScale)
		@test c_major isa Scale{Pitch{C, Natural, 4}, MajorScale}
		@test c_major[1] isa Pitch{C, Natural, 4}
		@test c_major[2] isa Pitch{D, Natural, 4}
		@test c_major[3] isa Pitch{E, Natural, 4}
		@test c_major[4] isa Pitch{F, Natural, 4}
		@test c_major[5] isa Pitch{G, Natural, 4}
		@test c_major[6] isa Pitch{A, Natural, 4}
		@test c_major[7] isa Pitch{B, Natural, 4}
		@test c_major[8] isa Pitch{C, Natural, 5}  # Octave
		a_minor = Scale(Pitch(A, 3), NaturalMinorScale)
		@test a_minor[1] isa Pitch{A, Natural, 3}
		@test a_minor[3] isa Pitch{C, Natural, 4}  # Minor third
		d_major = Scale(Pitch(D, 4), MajorScale)
		@test d_major[1] isa Pitch{D, Natural, 4}
		@test d_major[3] isa Pitch{F, Sharp, 4}  # F# in D major
	end
	
	@testset "Chords" begin
		c = Pitch(C, 4)
		e = Pitch(E, 4)
		g = Pitch(G, 4)
		c_major_chord = Chord(c, e, g)
		@test c_major_chord isa Chord
		c_major_triad = majortriad(c)
		@test c_major_triad isa Chord
		a_minor_triad = minortriad(Pitch(A, 3))
		@test a_minor_triad isa Chord
		@test is_major_triad(typeof(c_major_triad))
	end
	
	@testset "Type stability" begin
		c = Pitch(C, 4)
		@test (@inferred c + MajorThird()) isa Pitch{E, Natural, 4}
		@test (@inferred semitone(c)) == 60
		@test (@inferred majortriad(c)) isa Chord
		@test @allocated(c + MajorThird()) == 0
		@test @allocated(semitone(c)) == 0
		@test @allocated(majortriad(c)) == 0
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
		
		# But are different types
		@test !(typeof(c_sharp) == typeof(d_flat))
		
		# Intervals that wrap around
		b4 = Pitch(B, 4)
		@test semitone(b4 + MinorSecond) == semitone(Pitch(C, 5))
	end
	
	@testset "Compile-time guarantees" begin
		# Test that scale degrees are computed at compile time
		scale = Scale(Pitch(C, 4), MajorScale)
		
		# This should be fully resolved at compile time
		third_degree_type = typeof(degree(scale, Val(3)))
		@test third_degree_type == Pitch{E, Natural, 4}
	end
	
	@testset "Performance benchmarks" begin
		c = Pitch(C, 4)
		
		# These should be essentially free
		b_pitch_creation = @benchmark Pitch(C, 4)
		@test median(b_pitch_creation.times) < 10  # nanoseconds
		
		b_interval_add = @benchmark $c + MajorThird
		@test median(b_interval_add.times) < 10
		
		b_semitone = @benchmark semitone($c)
		@test median(b_semitone.times) < 10
		
		# No allocations
		@test b_pitch_creation.allocs == 0
		@test b_interval_add.allocs == 0
		@test b_semitone.allocs == 0
	end
end

