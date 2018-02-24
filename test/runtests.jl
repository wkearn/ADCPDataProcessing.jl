using TidalFluxQuantities, TidalFluxConfigurations, PIEMetData, ADCPDataProcessing, TidalFluxExampleData
using Base.Test

TidalFluxConfigurations.config[:_ADCPDATA_DIR] = Pkg.dir("TidalFluxExampleData","data","adcp")
TidalFluxConfigurations.config[:_METDATA_DIR] = Pkg.dir("TidalFluxExampleData","data","met")

creek = Creek{:sweeney}()
deps = parse_deps(creek)
adata = load_data.(deps)

cs = parse_cs(creek)
csd = load_data(cs)

p,Q = computedischarge(adata[1],csd)

cals = parse_cals(creek)
cc = load_data(IndexDischarge,cals[1])
cv = load_data(IndexVelocity,cals[1])

include("mask.jl")
include("hdf5.jl")
