export CalibrationDeployment, parse_cals

#####################################################
# Definition of Calibration type and loading
# calibration definitions from METADATA.json

type CalibrationDeployment
    id::String
    deployment::Deployment
    cs::CrossSection
    startDate::DateTime
    endDate::DateTime
end

function Base.show(io::IO,cal::CalibrationDeployment)
    println(io,"Calibration")
    println(io,"------------")
    println(io,"Start time: ",cal.startDate)
    println(io,"End time: ",cal.endDate)
    print(io,cal.deployment)    
end

function parse_cals{C}(creek::Creek{C},ADCPdatadir=adcp_data_directory[:_ADCPDATA_DIR])
    cs = parse_cs(creek)
    deps = parse_deps(creek)
    ids = map(x->x.id,deps)
    d = JSON.parsefile(joinpath(ADCPdatadir,string(C),"METADATA.json"))
    cals = CalibrationDeployment[]
    for cal in d["calibrations"]
        id = cal["id"]
        dep = cal["deployment"]
        sD = DateTime(cal["startDate"])
        eD = DateTime(cal["endDate"])
        dep_match = findfirst(ids,dep)
        push!(cals,CalibrationDeployment(id,deps[dep_match],cs,sD,eD))
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

function load_data(cal::CalibrationDeployment,ADCPdatadir=adcp_data_directory[:_ADCPDATA_DIR])
    # Load ADCP data and convert to discharges
    ad = load_data(cal.deployment)
    cs = load_data(cal.cs)
    _,dd = computedischarge(ad,cs)
    
    data_dir = joinpath(ADCPdatadir,
                        string(cal.deployment.location),
                        "calibrations",
                        cal.id)
    D = readtable(joinpath(data_dir,"discharge_calibrations.csv"))
    dc = Discharge(DateTime(D[:DateTime]),D[:SP_Q])
    Calibration(dc,dd)
end

function load_data(cal::CalibrationDeployment,flag::Bool,ADCPdatadir=adcp_data_directory[:_ADCPDATA_DIR])
    # Load ADCP data and convert to discharges
    ad = load_data(cal.deployment)
    cs = load_data(cal.cs)
    hh,dd,AA,vv = computedischarge(ad,cs,flag)
    
    data_dir = joinpath(ADCPdatadir,
                        string(cal.deployment.location),
                        "calibrations",
                        cal.id)
    D = readtable(joinpath(data_dir,"discharge_calibrations.csv"))
    dc = Discharge(DateTime(D[:DateTime]),D[:SP_Q])
    Calibration(dc,dd),(hh,AA,vv)
end
