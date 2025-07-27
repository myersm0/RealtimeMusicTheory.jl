
abstract type AbstractScale end

abstract type DiatonicScale <: AbstractScale end
struct MajorScale <: DiatonicScale end
struct NaturalMinorScale <: DiatonicScale end
struct HarmonicMinorScale <: DiatonicScale end
struct MelodicMinorScale <: DiatonicScale end
struct ChromaticScale <: AbstractScale end

const MinorScale = NaturalMinorScale

# Scale patterns (using chromatic steps)
scale_pattern(::Type{MajorScale}) = (
	ChromaticStep{2}, ChromaticStep{2}, ChromaticStep{1},
	ChromaticStep{2}, ChromaticStep{2}, ChromaticStep{2}, ChromaticStep{1}
)

scale_pattern(::Type{NaturalMinorScale}) = (
	ChromaticStep{2}, ChromaticStep{1}, ChromaticStep{2},
	ChromaticStep{2}, ChromaticStep{1}, ChromaticStep{2}, ChromaticStep{2}
)

scale_pattern(::Type{HarmonicMinorScale}) = (
	ChromaticStep{2}, ChromaticStep{1}, ChromaticStep{2},
	ChromaticStep{2}, ChromaticStep{1}, ChromaticStep{3}, ChromaticStep{1}
)

scale_pattern(::Type{MelodicMinorScale}) = (
	ChromaticStep{2}, ChromaticStep{1}, ChromaticStep{2},
	ChromaticStep{2}, ChromaticStep{2}, ChromaticStep{2}, ChromaticStep{1}
)

scale_pattern(::Type{ChromaticScale}) = ntuple(_ -> ChromaticStep{1}, 11)

struct Scale{PitchClasses <: Tuple} end

@generated function Scale(::Type{ST}, ::Type{Root}) where {ST <: AbstractScale, Root <: PitchClass}
	pattern = scale_pattern(ST)
	pitches = Type[Root]
	current = Root
	for step in pattern[1:end-1]
		semi = step.parameters[1]
		current = add_semitones(current, semi)
		push!(pitches, current)
	end
	return :(Scale{Tuple{$(pitches...)}})
end

@generated function Base.findfirst(::Type{Scale{PCs}}, ::Type{PC}) where {PCs, PC <: PitchClass}
	for (i, p) in enumerate(PCs.parameters)
		p == PC && return :($(i))  # warning: 1-indexed rather than 0; will this be a problem?
	end
	return :(nothing)
end

struct ScaleDegree{N} end

# Functional names
abstract type ScaleFunction end
struct Tonic <: ScaleFunction end
struct Supertonic <: ScaleFunction end
struct Mediant <: ScaleFunction end
struct Subdominant <: ScaleFunction end
struct Dominant <: ScaleFunction end
struct Submediant <: ScaleFunction end
struct LeadingTone <: ScaleFunction end
struct Subtonic <: ScaleFunction end

# Map functions to degrees
scale_degree(::Type{Tonic}) = ScaleDegree{1}
scale_degree(::Type{Supertonic}) = ScaleDegree{2}
scale_degree(::Type{Mediant}) = ScaleDegree{3}
scale_degree(::Type{Subdominant}) = ScaleDegree{4}
scale_degree(::Type{Dominant}) = ScaleDegree{5}
scale_degree(::Type{Submediant}) = ScaleDegree{6}
scale_degree(::Type{LeadingTone}) = ScaleDegree{7}
scale_degree(::Type{Subtonic}) = ScaleDegree{7}

@generated function Base.getindex(::Type{Scale{PCs}}, ::Type{ScaleDegree{N}}) where {PCs, N}
	elements = PCs.parameters
	pc = elements[mod1(N, length(elements))]
	return :($pc)
end

@generated function Base.getindex(::Type{Scale{PCs}}, ::Type{F}) where {PCs, F <: ScaleFunction}
	deg = scale_degree(F)
	n = deg.parameters[1]
	pc = PCs.parameters[mod1(n, length(PCs.parameters))]
	:($pc)
end

