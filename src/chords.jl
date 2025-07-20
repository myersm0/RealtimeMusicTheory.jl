
struct Chord{Pitches <: Tuple} end

Chord(pitches::Pitch...) = Chord{typeof(pitches)}()

majortriad(root::P) where P <: Pitch = Chord(root, root + MajorThird, root + PerfectFifth)
minortriad(root::P) where P <: Pitch = Chord(root, root + MinorThird, root + PerfectFifth)

is_major_triad(::Type{Chord{Tuple{R, T, F}}}) where {R, T, F} = 
	T == typeof(R() + MajorThird) && F == typeof(R() + PerfectFifth)

