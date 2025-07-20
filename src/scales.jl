
abstract type ScalePattern end
struct MajorScale <: ScalePattern end
struct NaturalMinorScale <: ScalePattern end
struct HarmonicMinorScale <: ScalePattern end

scale_intervals(::Type{MajorScale}) = (
	MajorSecond, MajorSecond, MinorSecond,
	MajorSecond, MajorSecond, MajorSecond, MinorSecond
)

scale_intervals(::Type{NaturalMinorScale}) = (
	MajorSecond, MinorSecond, MajorSecond,
	MajorSecond, MinorSecond, MajorSecond, MajorSecond
)

struct Scale{Tonic <: Pitch, Pattern <: ScalePattern} end

Scale(tonic::T, ::Type{P}) where {T <: Pitch, P <: ScalePattern} = Scale{T, P}()

@generated function degree(::Scale{Tonic, Pattern}, ::Val{N}) where {Tonic, Pattern, N}
	intervals = scale_intervals(Pattern)
	# calculate the pitch by adding intervals
	pitch_expr = :(Tonic())
	for i in 1:(N-1)
		interval = intervals[mod1(i, length(intervals))]
		pitch_expr = :($pitch_expr + $interval)
	end
	return pitch_expr
end

Base.getindex(s::Scale, n::Int) = degree(s, Val(n))

