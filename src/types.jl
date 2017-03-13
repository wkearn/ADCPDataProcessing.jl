export Creek, Deployment, CrossSection, bins, parse_deps, parse_cs

type Creek{C}
    
end

Base.string{C}(::Creek{C}) = string(C)
Base.show(io::IO,creek::Creek) = print(io,"Creek: ", string(creek))

type ADCP
    serialNumber::String
    hasAnalog::Bool
    blankingDistance::Real
    cellSize::Real
    nCells::Int
    deltaT::Real
    elevation::Real
end

function bins(adcp::ADCP)
    B = adcp.blankingDistance
    C = adcp.cellSize
    N = adcp.nCells
    [B+C*i for i in 1:N]
end

function Base.show(io::IO,adcp::ADCP)
    println(io,"ADCP ",adcp.serialNumber)
    print(io,"Analog?: ", adcp.hasAnalog)
end


type Deployment
    location::Creek
    startDate::DateTime
    endDate::DateTime
    adcp::ADCP
end

function Base.show(io::IO,dep::Deployment)
    println(io,"ADCP Deployment")
    println(io,"================")
    println(io,dep.location)
    println(io,"Start time: ",dep.startDate)
    println(io,"End time: ",dep.endDate)
    print(io,dep.adcp)
end

type CrossSection
    location::Creek
    file::String
    Amax::Real
    lmax::Real
    hmax::Real
end

function Base.show(io::IO,cs::CrossSection)
    println(io,"Cross-section")
    println(io,"______________")
    print(io,cs.location)
end

function parse_deps{C}(creek::Creek{C},ADCPdatadir=data_directories[:_ADCPDATA_DIR])
    d = JSON.parsefile(joinpath(ADCPdatadir,string(C),"METADATA.json"))
    deps = Deployment[]
    for dep in d["deployments"]
        sd = DateTime(dep["startDate"])
        ed = DateTime(dep["endDate"])
        sN = dep["serialNumber"]
        hA = dep["hasAnalog"]
        bD = dep["blankingDistance"]
        cS = dep["cellSize"]
        nC = dep["nCells"]
        dT = dep["deltaT"]
        aZ = dep["elevation"]
        push!(deps,Deployment(creek,sd,ed,ADCP(sN,hA,bD,cS,nC,dT,aZ)))
    end
    deps
end

function parse_cs{C}(creek::Creek{C},ADCPdatadir=data_directories[:_ADCPDATA_DIR])
    cs = JSON.parsefile(joinpath(ADCPdatadir,string(C),"METADATA.json"))["cross-section"]
    f = cs["file"]
    Amax = cs["Amax"]
    lmax = cs["lmax"]
    hmax = cs["hmax"]
    CrossSection(creek,f,Amax,lmax,hmax)
end

Base.hash{C}(x::Creek{C},h::UInt) = hash(C,h)
function Base.hash(x::ADCP,h::UInt)
    h = hash(x.serialNumber,h)
    h = hash(x.hasAnalog,h)
    h = hash(x.blankingDistance,h)
    h = hash(x.cellSize,h)
    h = hash(x.nCells,h)
    h = hash(x.deltaT,h)
    h = hash(x.elevation,h)
end

function Base.hash(x::Deployment,h::UInt)
    h = hash(x.location,h)
    h = hash(x.startDate,h)
    h = hash(x.endDate,h)
    hash(x.adcp,h)
end

function Base.hash(x::CrossSection,h::UInt)
    h = hash(x.location,h)
    h = hash(x.file,h)
    h = hash(x.Amax,h)
    h = hash(x.lmax,h)
    h = hash(x.hmax,h)
end

Base.:(==)(c1::Creek,c2::Creek) = hash(c1)==hash(c2)
Base.:(==)(d1::Deployment,d2::Deployment) = hash(d1)==hash(d2)
Base.:(==)(a1::ADCP,a2::ADCP) = hash(a1)==hash(a2)
Base.:(==)(cs1::CrossSection,cs2::CrossSection) = hash(cs1)==hash(cs2)
