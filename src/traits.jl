
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
abstract type LinearDirection end
struct Left <: LinearDirection end
struct Right <: LinearDirection end
abstract type CircularDirection end
struct Clockwise <: CircularDirection end
struct Counterclockwise <: CircularDirection end

negative_direction(::Linear) = Left
positive_direction(::Linear) = Right
positive_direction(::Circular) = Clockwise
negative_direction(::Circular) = Counterclockwise

Base.sign(::Type{Left}) = -1
Base.sign(::Type{Right}) = 1
Base.sign(::Type{Clockwise}) = 1
Base.sign(::Type{Counterclockwise}) = -1

Base.:*(::Type{D}, x) where D <: Direction = sign(D) * x
Base.:*(x, ::Type{D}) where D <: Direction = sign(D) * x

