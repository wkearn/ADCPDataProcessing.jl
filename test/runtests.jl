using PIEMetData, ADCPDataProcessing, TidalFluxExampleData
using Base.Test

setADCPdatadir!(Pkg.dir("TidalFluxExampleData","data","adcp"))
setmetdatadir!(Pkg.dir("TidalFluxExampleData","data","met"))

creek = Creek{:sweeney}()
deps = parse_deps(creek)
adata = load_data.(deps)

cs = parse_cs(creek)
csd = load_data(cs)

Discharge(adata[1],csd)
