#===================================================================================================
    <Schema>
===================================================================================================#
type Schema{RowsKnown}
    header::Vector{String}       # column names
    types::Vector{DataType}      # Julia types of columns
    rows::Int                    # number of rows in the dataset
    cols::Int                    # number of columns in a dataset
    metadata::Dict{Any, Any}     # for any other metadata we'd like to keep around
                                 #  (not used for '==' operation)
    index::Dict{String,Int}      # maps column names as Strings to their index # in `header` and `types`
end


# primary constructor
function Schema(header::Vector, types::Vector{DataType}, rows::Integer=0, metadata::Dict=Dict())
    if rows < -1
        throw(ArgumentError("Invalid # of rows for Schema; use -1 to indicate an unknown # of rows"))
    end
    cols = length(header)
    if cols ≠ length(types)
        throw(ArgumentError("length(header): $(length(header)) must == length(types): $(length(types))"))
    end
    header = String[string(x) for x in header]
    return Schema{rows > -1}(header, types, rows, cols, metadata,
                             Dict(n=>i for (i, n) ∈ enumerate(header)))
end

function Schema(types::Vector{DataType}, rows::Integer=0, meta::Dict=Dict())
    Schema(String["Column$i" for i = 1:length(types)], types, rows, meta)
end
Schema() = Schema(String[], DataType[], 0, Dict())

header(sch::Schema) = sch.header
header(::Type{Symbol}, sch::Schema) = Symbol[Symbol(s) for s ∈ header(sch)]
types(sch::Schema) = sch.types
types(sch::Schema, col) = types(sch)[col]
types(sch::Schema, col::Union{<:AbstractString,Symbol}) = types(sch, sch[col])
Base.size(sch::Schema) = (sch.rows, sch.cols)
Base.size(sch::Schema, i::Int) = ifelse(i == 1, sch.rows, ifelse(i == 2, sch.cols, 0))

header(source_or_sink) = header(schema(source_or_sink))
# this should be removed, because it only operates on the schema, not the source or sink
# setrows!(source, rows) = isdefined(source, :schema) ? (source.schema.rows = rows; nothing) : nothing

Base.getindex(sch::Schema, col::Union{<:AbstractString,Symbol}) = sch.index[string(col)]

function Base.show{b}(io::IO, schema::Schema{b})
    println(io, "Data.Schema{$(b)}:")
    println(io, "rows: $(schema.rows)\tcols: $(schema.cols)")
    if schema.cols <= 0
        println(io)
    else
        println(io, "Columns:")
        Base.print_matrix(io, hcat(schema.header, schema.types))
    end
end

function transform(sch::Data.Schema, transforms::Dict{Int,Function})
    types = Data.types(sch)
    newtypes = similar(types)
    transforms2 = Array{Function}(length(types))
    for (i, T) in enumerate(types)
        f = get(transforms, i, identity)
        newtypes[i] = Core.Inference.return_type(f, (T,))
        transforms2[i] = f
    end
    return Schema(Data.header(sch), newtypes, size(sch, 1), sch.metadata), transforms2
end
function transform(sch::Data.Schema, transforms::Dict{<:Union{String,Symbol},Function})
    transform(sch, Dict{Int,Function}(sch[string(x)]=>f for (x,f) in transforms))
end


function _checkcolsmatch(sch1::Schema, sch2::Schema)
    if size(sch1,2) ≠ size(sch2,2)
        throw(ArgumentError("Can only stream between tables with equal numbers of columns."))
    end
end

# worried about compiler type inference issues when using these
default_transform(sch::Schema, col) = (x -> convert(types(sch, col), x))
default_transforms(sch::Schema) = default_transform.(sch, 1:size(sch,2))


# default iterator over rows
iterrows(sch::Schema) = 1:size(sch, 1)
# default iterator over columns
itercols(sch::Schema) = 1:size(sch, 2)
#===================================================================================================
    </Schema>
===================================================================================================#


