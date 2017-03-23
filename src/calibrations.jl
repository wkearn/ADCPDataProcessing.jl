export CalibrationDeployment, parse_cals

#####################################################
# Definition of Calibration type and loading
# calibration definitions from METADATA.json

type CalibrationDeployment
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

function parse_cals{C}(creek::Creek{C})
    cs = parse_cs(creek)
    deps = parse_deps(creek)
    hs = hash.(deps)
    d = JSON.parsefile(joinpath(_DATABASE_DIR,string(C),"METADATA.json"))
    cals = Calibration[]
    for cal in d["calibrations"]
        dep = cal["deployment"]
        sD = DateTime(cal["startDate"])
        eD = DateTime(cal["endDate"])
        dep_match = findfirst(hex.(hs,16),dep)
        push!(cals,CalibrationDeployment(deps[dep_match],cs,sD,eD))
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

function load_data(cal::CalibrationDeployment)
    # Load ADCP data and convert to discharges
    ad = load_data(cal.deployment)
    cs = load_data(cal.cs)
    dd = Discharge(ad,cs)
    
    data_dir = joinpath(_DATABASE_DIR,
                        string(cal.deployment.location),
                        "calibrations",
                        hex(hash(cal),16))
    D = readtable(joinpath(data_dir,"discharge_calibrations.csv"))
    Calibration(cal,DateTime(D[:DateTime]),D[:SP_Q],dd)
end
