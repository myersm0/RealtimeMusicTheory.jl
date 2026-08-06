
## traits relating to classification of a MusicalSpace (to be defined later)
abstract type SpellingStyle end
abstract type GenericSpelling <: SpellingStyle end
abstract type SpecificSpelling <: SpellingStyle end

abstract type RegisterStyle end
abstract type ClassLevel <: RegisterStyle end
abstract type Registral <: RegisterStyle end

abstract type TopologyStyle end
abstract type Linear <: TopologyStyle end
abstract type Circular <: TopologyStyle end

## topology-related traits
abstract type Direction end
abstract type LinearDirection <: Direction end
struct Left <: LinearDirection end
struct Right <: LinearDirection end
abstract type CircularDirection <: Direction end
struct Clockwise <: CircularDirection end
struct Counterclockwise <: CircularDirection end

positive_direction(::Type{Linear}) = Right
negative_direction(::Type{Linear}) = Left
positive_direction(::Type{Circular}) = Clockwise
negative_direction(::Type{Circular}) = Counterclockwise

Base.sign(::Type{Left}) = -1
Base.sign(::Type{Right}) = 1
Base.sign(::Type{Clockwise}) = 1
Base.sign(::Type{Counterclockwise}) = -1

Base.:*(::Type{D}, x) where D <: Direction = sign(D) * x
Base.:*(x, ::Type{D}) where D <: Direction = sign(D) * x
Base.:*(::Type{D1}, ::Type{D2}) where {D1 <: Direction, D2 <: Direction} = sign(D1) * sign(D2)

