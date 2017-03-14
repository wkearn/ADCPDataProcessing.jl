module ADCPDataProcessing

using DischargeData, JSON, DataFrames

include("databases.jl")
include("types.jl")
include("data.jl")
include("discharge.jl")

end # module
