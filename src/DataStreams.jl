__precompile__(true)

module DataStreams

export Data

module Data

using NullableArrays


abstract type StreamType end
struct Column <: StreamType end
struct Row <: StreamType end

include("schema.jl")
include("source_sink.jl")
include("streaming.jl")



end # module Data
end # module DataStreams2

