
abstract type ScalePattern end
abstract type DiatonicScale <: ScalePattern end
struct MajorScale <: DiatonicScale end
struct NaturalMinorScale <: DiatonicScale end
struct HarmonicMinorScale <: DiatonicScale end
struct MelodicMinorScale <: DiatonicScale end
struct ChromaticScale <: ScalePattern end

const MinorScale = NaturalMinorScale

struct Scale{PCs <: Tuple} <: AbstractScale{PitchClass} end
struct RealizedScale{Ps <: Tuple} <: AbstractScale{Pitch} end

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

@generated function Scale(::Type{ST}, ::Type{Root}) where {ST <: DiatonicScale, Root <: PitchClass}
	pattern = scale_pattern(ST)
	root_letter = letter(Root)
	root_acc = accidental(Root)
	root_semi = semitone(Root)
	pitches = Type[] # for diatonic scales we need each letter exactly once
	push!(pitches, Root)
	cumulative_semis = 0
	current_letter = root_letter
	for (i, step) in enumerate(pattern[1:end-1])
		current_letter = letter_step(current_letter, 1)
		cumulative_semis += step.parameters[1]
		target_semi = mod(root_semi + cumulative_semis, 12)
		natural_semi = chromatic_position(current_letter)
		offset = target_semi - natural_semi
		if offset > 6
			offset -= 12
		elseif offset < -6
			offset += 12
		end
		acc = offset == -2 ? DoubleFlat :
			offset == -1 ? Flat :
			offset == 0 ? Natural :
			offset == 1 ? Sharp :
			offset == 2 ? DoubleSharp :
			error("Invalid scale step")
		push!(pitches, PitchClass{current_letter, acc})
	end
	return :(Scale{Tuple{$(pitches...)}})
end

@generated function Scale(::Type{ChromaticScale}, ::Type{Root}) where {Root <: PitchClass}
	pattern = scale_pattern(ChromaticScale)
	pitches = Type[Root]
	current = Root
	for step in pattern
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

ScaleDegree(n::Int) = ScaleDegree{n}

abstract type ScaleFunction end
struct Tonic <: ScaleFunction end
struct Supertonic <: ScaleFunction end
struct Mediant <: ScaleFunction end
struct Subdominant <: ScaleFunction end
struct Dominant <: ScaleFunction end
struct Submediant <: ScaleFunction end
struct LeadingTone <: ScaleFunction end
struct Subtonic <: ScaleFunction end

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

tonic(s::Type{Scale{PCs}}) where PCs = s[Tonic]
supertonic(s::Type{Scale{PCs}}) where PCs = s[supertonic]
mediant(s::Type{Scale{PCs}}) where PCs = s[mediant]
subdominant(s::Type{Scale{PCs}}) where PCs = s[subdominant]
dominant(s::Type{Scale{PCs}}) where PCs = s[dominant]
submediant(s::Type{Scale{PCs}}) where PCs = s[submediant]
leadingtone(s::Type{Scale{PCs}}) where PCs = s[leadingtone]
subtonic(s::Type{Scale{PCs}}) where PCs = s[subtonic]

@generated function realize(::Type{Scale{PCs}}, ::Type{Pitch{PC, Register}}) where {PCs, PC, Register}
	start_pos = nothing
	for (i, pc) in enumerate(PCs.parameters)
		if pc == PC
			start_pos = i - 1
			break
		end
	end
	!isnothing(start_pos) || error("Starting pitch not in scale")
	pitches = Type[]
	current_register = Register
	last_pos = start_pos
	for i in 0:length(PCs.parameters)-1
		pos = mod(start_pos + i, length(PCs.parameters))
		pc = PCs.parameters[pos + 1]
		# check if we've wrapped around (gone up an octave)
		if pos < last_pos
			current_register += 1
		end
		last_pos = pos
		push!(pitches, Pitch{pc, current_register})
	end
	return :(RealizedScale{Tuple{$(pitches...)}})
end

function realize(s::Type{Scale{PCs}}, register::Int = 4) where PCs
	return realize(s, Pitch(tonic(s), register))
end

function realize(s::Type{Scale{PCs}}, ::Type{SF}, register::Int = 4) where {PCs, SF <: Union{ScaleDegree, ScaleFunction}}
	return realize(s, Pitch(s[SF], register))
end










