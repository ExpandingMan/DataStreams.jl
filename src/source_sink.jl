#===================================================================================================
    <Source>
===================================================================================================#
# Data.Source interface
abstract type Source end

# required methods
function schema end
function isdone end
function streamfron end

# optional method
function reference end

# generic fallbacks
Base.size(s::Source) = size(schema(s))
Base.size(s::Source, i) = size(schema(s), i)
reference(x) = UInt8[]
#===================================================================================================
    </Source>
===================================================================================================#


#===================================================================================================
    <Sink>
===================================================================================================#
# Data.Sink interface
abstract type Sink end

# required methods
function streamto! end

# optional methods
function cleanup! end
function close! end

function allocate! end

# generic fallbacks
cleanup!(sink) = ()
close!(sink) = ()
#===================================================================================================
    </Sink>
===================================================================================================#


#===================================================================================================
    <Common> (for both Source and Sink)

    # TODO users should be able to define vectortype by column
===================================================================================================#
streamtype(s) = Data.Column
vectortype{T}(s, ::Type{T}) = Vector{T}
vectortype{T}(s, ::Type{Nullable{T}}) = NullableVector{T}

vectorconstruct(s, ::Type{T}, n::Integer) = vectortype(s, T)(n)

vectorconvert(s, ::Type{T}, x) = convert(vectortype(s, T), x)
#===================================================================================================
    </Common>
===================================================================================================#


