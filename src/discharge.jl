using PIEMetData, DataFrames, Interpolations, Base.Dates

export atmoscorrect, InterpolatedCrossSectionData, ADCPDataCP,
area, computedischarge

typealias ADCPDataCP ADCPData

# We should change types to an ADCPDataCP or something here
# so that we don't use the wrong pressure data at some point
function atmoscorrect(adcp::ADCPData)
    M = parsemet(year(deployment(adcp).startDate))
    t = times(adcp)
    p = pressures(adcp)
    pc = M[:P]/100 - 10.1325 # Convert to dbar and subtract 1 atm (in dbar)
    Pi = interpolate((M[:DateTime],),float(pc),Gridded(Linear()))
    ph = p-Pi[t] # hydrodynamic pressure
    cp = ph*100000./(10*9.81*1025) # Convert pressure in dbar to m
    Stage(t,cp)
end

type InterpolatedCrossSectionData
    cs::CrossSection
    cszi::AbstractInterpolation
    function InterpolatedCrossSectionData(cs::CrossSectionData)
        new(cs.cs,interpolate((cs.x,),cs.z,Gridded(Linear())))
    end
end

function area(cs::InterpolatedCrossSectionData,h)
    cszi = cs.cszi
    cg = cszi.knots[1]
    csf(x) = cszi[x]>h?h:cszi[x]
    quadgk(x->(h-csf(x)),cg[1],cg[end])[1]
end

function findzeros(cszi,h)
    dt = 0.00001
    n = length(cszi.knots[1])
    s = cszi.knots[1][1]
    err = h-cszi[s]
    while err < 0
        s+=dt
        err = h-cszi[s]
    end
    a = s
    s = cszi.knots[1][end]
    err = h-cszi[s]
    while err < 0
        s-=dt
        err = h-cszi[s]
    end
    b = s
    return a,b
end

# We need a way to turn a Nx3 array into an N vector of
# tuples
tupleize(X::AbstractArray{Float64,2}) = [(X[i,:]...) for i in 1:size(X,1)]
detupleize(T::AbstractVector{Tuple{Float64,Float64,Float64}}) = vcat([[T[i]...]' for i in 1:length(T)]...)

function vavg(pq::Stage,V::Array{Float64,3},bs::AbstractVector,α=cosd(25))
    p = quantity(pq)
    t = DischargeData.times(pq)
    tops = zeros(Int,length(p))
    for i in 1:length(p)
        q = find(x->x<p[i]*α,bs)
        tops[i] = isempty(q) ? 0 : q[end]
    end
    vma = zeros(length(p),3)
    for i in 1:length(p)
        for j in 1:3
            r = tops[i]
            if r == 0
                vma[i,j] = 0.0
            else
                vma[i,j] = mean(V[1:r,i,j])
            end
        end
    end
    Velocity(t,tupleize(vma))    
end

function polyFit(h,A,k)
    X = zeros(length(h),k+1)
    for i in 0:k
        X[:,i+1] = h.^i
    end
    X\A
end

function applyPolyFit(a,h::Vector{Float64})
    k = length(a)-1
    b = a[k+1]*ones(h)
    for i in k:-1:1
        b = a[i] + b.*h
    end
    b
end

function rotate(V::Velocity)
    vma = detupleize(quantity(V))
    ts = DischargeData.times(V)
    l,Z = eig(cov(vma))
    AlongChannelVelocity(ts,vma*Z[:,3])
end

function computearea(E,h::Stage,cs::CrossSectionData)
    ts,hs = unzip(h)
    csdi = InterpolatedCrossSectionData(cs)
    htest = E+0.01:0.01:maximum(hs)+E
    Ah = map(x->area(csdi,x),htest)
    b = polyFit(htest,Ah,5)
    CrossSectionalArea(ts,applyPolyFit(b,hs+E))
end

function computedischarge(adcp::ADCPData,cs::CrossSectionData,α=cosd(25))
    E = adcp.dep.adcp.elevation
    cd1 = atmoscorrect(adcp)
    ts,cp = unzip(cd1)
    V = vavg(cd1,adcp.v,bins(adcp.dep.adcp),α) # :: Velocity
    vs = rotate(V) # :: AlongChannelVelocity
    A = computearea(E,cd1,cs) # :: CrossSectionalArea
    Q = A*vs # :: Discharge
    Qi = fixOrientation(cd1,Q) # :: Discharge
    cd1, Qi
end

function computedischarge(adcp::ADCPData,cs::CrossSectionData,flag::Bool,α=cosd(25))
    E = adcp.dep.adcp.elevation
    cd1 = atmoscorrect(adcp)
    ts,cp = unzip(cd1)
    V = vavg(cd1,adcp.v,bins(adcp.dep.adcp),α) # :: Velocity
    vs = rotate(V) # :: AlongChannelVelocity
    A = computearea(E,cd1,cs) # :: CrossSectionalArea
    Q = A*vs # :: Discharge
    Qi = fixOrientation(cd1,Q) # :: Discharge
    if flag
        vi = fixOrientation(cd1,vs)
        return cd1, Qi, A, vi
    else
        return cd1, Qi
    end
end

# A quick, dirty and not great way to fix the sign of Q
function detectOrientation(cp::Vector{Float64},Q::Vector{Float64})
    N1 = countnz(sign(gradient(cp)) .== sign(Q))
    N2 = countnz(sign(gradient(cp)) .== sign(-Q))
    N1 > N2 ? 1.0 : -1.0
end

function fixOrientation(h::Stage,Q::Quantity)
    s = detectOrientation(quantity(h),quantity(Q))
    Discharge(DischargeData.times(Q),quantity(Q).*s)
end
