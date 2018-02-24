using TidalFluxCalibrations
    
export CalibrationDeployment,
    parse_cals,
    IndexDischarge,
    IndexVelocity

#####################################################
# Definition of Calibration type and loading
# calibration definitions from METADATA.json

type CalibrationDeployment
    id::String
    deployment::Deployment
    cs::CrossSection
    startDate::DateTime
    endDate::DateTime
    quantities::Array{String,1}
end

function Base.show(io::IO,cal::CalibrationDeployment)
    println(io,"Calibration")
    println(io,"------------")
    println(io,"Start time: ",cal.startDate)
    println(io,"End time: ",cal.endDate)
    print(io,cal.deployment)    
end

quantities_map = Dict{String,UnionAll}("discharge" => Discharge,
                                       "velocity" => AlongChannelVelocity,
                                       "tss" => TSS)
                                      
function parse_cals{C}(creek::Creek{C},ADCPdatadir=TidalFluxConfigurations.config[:_ADCPDATA_DIR],schema=metadataschema)
    cs = parse_cs(creek)
    deps = parse_deps(creek)
    ids = map(x->x.id,deps)
    d = metadataload(creek,ADCPdatadir,schema)
    cals = CalibrationDeployment[]
    for cal in d["calibrations"]
        id = cal["id"]
        dep = cal["deployment"]
        sD = DateTime(cal["startDate"])
        eD = DateTime(cal["endDate"])
        qs = cal["quantities"]
        dep_match = findfirst(ids,dep)
        push!(cals,CalibrationDeployment(id,deps[dep_match],cs,sD,eD,qs))
    end
    cals
end

function Base.hash(x::CalibrationDeployment,h::UInt)
    h = hash(x.deployment,h)
    h = hash(x.startDate,h)
    h = hash(x.endDate,h)
end

Base.:(==)(c1::CalibrationDeployment,c2::CalibrationDeployment) = hash(c1)==hash(c2)

#####################################################
# Loading calibration data

abstract type DischargeCalibrationMethod end

struct IndexVelocity <: DischargeCalibrationMethod end
struct IndexDischarge <: DischargeCalibrationMethod end

function load_datatable(cal::CalibrationDeployment,ADCPdatadir=TidalFluxConfigurations.config[:_ADCPDATA_DIR])
    data_dir = joinpath(ADCPdatadir,
                        string(cal.deployment.location),
                        "calibrations",
                        cal.id)
    CSV.read(joinpath(data_dir,"discharge_calibrations.csv"))
end

function load_data(::Type{IndexDischarge},cal::CalibrationDeployment,ADCPdatadir=TidalFluxConfigurations.config[:_ADCPDATA_DIR])
    if "discharge" ∉ cal.quantities
        error("Index discharge not collected for this calibration")
    end
    # Load ADCP data and convert to discharges
    ad = load_data(cal.deployment)
    cs = load_data(cal.cs)
    _,dd = computedischarge(ad,cs)
    
    D = load_datatable(cal,ADCPdatadir)
    # We need to convert the DataArray to an Array{Float64}
    # But only after the subtyping changes in TidalFluxQuantities
    dc = Discharge(DateTime.(D[:DateTime]),float(D[:SP_Q]))
    Calibration(dc,dd)
end

function load_data(::Type{IndexVelocity},cal::CalibrationDeployment,ADCPdatadir=TidalFluxConfigurations.config[:_ADCPDATA_DIR])
    if "velocity" ∉ cal.quantities
        error("Index velocity not collected for this calibration")
    end
    # Load ADCP data and convert to discharges
    ad = load_data(cal.deployment)
    cs = load_data(cal.cs)

    # We need to compute the velocities, not the discharges here
    dd = computevelocity(ad)
    
    D = load_datatable(cal,ADCPdatadir)

    # Here we load the velocities, not the discharges
    dc = AlongChannelVelocity(DateTime.(D[:DateTime]),float(D[:SP_V]))
    Calibration(dc,dd)
end

function load_data(cal::CalibrationDeployment,flag::Bool,ADCPdatadir=TidalFluxConfigurations.config[:_ADCPDATA_DIR])
    # Load ADCP data and convert to discharges
    ad = load_data(cal.deployment)
    cs = load_data(cal.cs)
    hh,dd,AA,vv = computedischarge(ad,cs,flag)
    
    D = load_datatable(cal,ADCPdatadir)
    dc = Discharge(DateTime.(D[:DateTime]),float(D[:SP_Q]))
    Calibration(dc,dd),hh,AA,vv
end

function load_tss_data(cal::CalibrationDeployment,islow=true,ADCPdatadir=TidalFluxConfigurations.config[:_ADCPDATA_DIR])
    # Load ADCP data and convert to discharges
    ad = load_data(cal.deployment)
    cs = load_data(cal.cs)
    dd = Turbidity(ad,islow)
    
    data_dir = joinpath(ADCPdatadir,
                        string(cal.deployment.location),
                        "calibrations",
                        cal.id)
    D = CSV.read(joinpath(data_dir,"tss_calibrations.csv"))
    # We need to convert the DataArray to an Array{Float64}
    # But only after the subtyping changes in TidalFluxQuantities
    dc = TSS(DateTime.(D[:DateTime]),float(D[:TSS]))
    Calibration(dc,dd)
end
