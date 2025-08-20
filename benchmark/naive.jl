
SUITE["naive"]["core"] = BenchmarkGroup()
SUITE["naive"]["core"]["pitch_class"] = @benchmarkable PitchClass(C, Natural)
SUITE["naive"]["core"]["pitch"] = @benchmarkable Pitch(C♮, 4)
SUITE["naive"]["core"]["letter"] = @benchmarkable letter(C♮)
SUITE["naive"]["core"]["accidental"] = @benchmarkable accidental(C♮)
SUITE["naive"]["core"]["number"] = @benchmarkable number(C♮)
SUITE["naive"]["core"]["pitch_to_midi"] = @benchmarkable number(Pitch(C♮, 4))

SUITE["naive"]["intervals"] = BenchmarkGroup()
# PitchClass + Interval
SUITE["naive"]["intervals"]["pc_major_third"] = @benchmarkable C♮ + M3
SUITE["naive"]["intervals"]["pc_perfect_fifth"] = @benchmarkable C♮ + P5
SUITE["naive"]["intervals"]["pc_minor_seventh"] = @benchmarkable C♮ + m7
# Pitch + Interval
SUITE["naive"]["intervals"]["pitch_major_third"] = @benchmarkable Pitch(C♮, 4) + M3
SUITE["naive"]["intervals"]["pitch_perfect_fifth"] = @benchmarkable Pitch(C♮, 4) + P5
SUITE["naive"]["intervals"]["pitch_octave"] = @benchmarkable Pitch(C♮, 4) + P8
# Interval construction
SUITE["naive"]["intervals"]["infer_major_third"] = @benchmarkable Interval(Pitch(C♮, 4), Pitch(E♮, 4))
SUITE["naive"]["intervals"]["infer_perfect_fifth"] = @benchmarkable Interval(Pitch(C♮, 4), Pitch(G♮, 4))
SUITE["naive"]["intervals"]["infer_octave"] = @benchmarkable Interval(Pitch(C♮, 4), Pitch(C♮, 5))
SUITE["naive"]["intervals"]["wide_interval"] = @benchmarkable Interval(Pitch(C♮, 2), Pitch(G♮, 6))

SUITE["naive"]["spaces"] = BenchmarkGroup()
# Distance
SUITE["naive"]["spaces"]["distance_chromatic"] = @benchmarkable distance(PitchClassSpace, C♮, G♮)
SUITE["naive"]["spaces"]["distance_letter"] = @benchmarkable distance(LetterSpace, C, G)
SUITE["naive"]["spaces"]["distance_fifths"] = @benchmarkable distance(LineOfFifths, C♮, G♮)
# Direction
SUITE["naive"]["spaces"]["direction_circle"] = @benchmarkable direction(CircleOfFifths, C♮, G♮)
SUITE["naive"]["spaces"]["direction_letter"] = @benchmarkable direction(LetterSpace, C, F)
# Number conversions in different spaces
SUITE["naive"]["spaces"]["number_pitch_class"] = @benchmarkable number(PitchClassSpace, C♮)
SUITE["naive"]["spaces"]["number_line_of_fifths"] = @benchmarkable number(LineOfFifths, C♮)

SUITE["naive"]["enharmonics"] = BenchmarkGroup()
SUITE["naive"]["enharmonics"]["is_enharmonic_true"] = @benchmarkable is_enharmonic(C♮, B♯)
SUITE["naive"]["enharmonics"]["is_enharmonic_false"] = @benchmarkable is_enharmonic(C♮, D♮)
SUITE["naive"]["enharmonics"]["is_enharmonic_exotic"] = @benchmarkable is_enharmonic(F𝄪, G♮)

SUITE["naive"]["patterns"] = BenchmarkGroup()
SUITE["naive"]["patterns"]["major_scale"] = @benchmarkable begin
	(Pitch(C♮, 4) + i for i in (P1, M2, M3, P4, P5, M6, M7, P8))
end

