export ADCP, Deployment, CrossSection, bins, parse_deps, parse_cs

type ADCP
    serialNumber::String
    hasAnalog::Bool
    obsSerialNumber::String
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
    id::String
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
end

function Base.show(io::IO,cs::CrossSection)
    println(io,"Cross-section")
    println(io,"______________")
    print(io,cs.location)
end

function parse_deps{C}(creek::Creek{C},ADCPdatadir=TidalFluxConfigurations.config[:_ADCPDATA_DIR],schema=metadataschema)
    d = metadataload(creek,ADCPdatadir,schema)
    deps = Deployment[]
    for dep in d["deployments"]
        id = dep["id"]
        sd = DateTime(dep["startDate"])
        ed = DateTime(dep["endDate"])
        sN = dep["serialNumber"]
        hA = dep["hasAnalog"]
        bD = dep["blankingDistance"]
        cS = dep["cellSize"]
        nC = dep["nCells"]
        dT = dep["deltaT"]
        aZ = dep["elevation"]
        oSN= get(dep,"obsSerialNumber","")
        push!(deps,Deployment(id,creek,sd,ed,ADCP(sN,hA,oSN,bD,cS,nC,dT,aZ)))
    end
    deps
end

function parse_cs{C}(creek::Creek{C},ADCPdatadir=TidalFluxConfigurations.config[:_ADCPDATA_DIR],schema=metadataschema)
    cs = metadataload(creek,ADCPdatadir,schema)["cross-section"]
    f = cs["file"]
    CrossSection(creek,f)
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
    h = hash(x.id,h)
    h = hash(x.location,h)
    h = hash(x.startDate,h)
    h = hash(x.endDate,h)
    hash(x.adcp,h)
end

function Base.hash(x::CrossSection,h::UInt)
    h = hash(x.location,h)
    h = hash(x.file,h)
end

Base.:(==)(c1::Creek,c2::Creek) = hash(c1)==hash(c2)
Base.:(==)(d1::Deployment,d2::Deployment) = hash(d1)==hash(d2)
Base.:(==)(a1::ADCP,a2::ADCP) = hash(a1)==hash(a2)
Base.:(==)(cs1::CrossSection,cs2::CrossSection) = hash(cs1)==hash(cs2)
