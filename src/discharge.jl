using PIEMetData, DataFrames, Interpolations, Base.Dates

export atmoscorrect, InterpolatedCrossSectionData, ADCPDataCP,
area

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
    ADCPDataCP(deployment(adcp),cp,velocities(adcp),times(adcp),temperatures(adcp),pitches(adcp),rolls(adcp),headings(adcp),analog(adcp)...)
end

type InterpolatedCrossSectionData
    cs::CrossSection
    cszi::AbstractInterpolation
    function InterpolatedCrossSectionData(cs::CrossSectionData)
        new(cs.cs,interpolate((cs.x,),cs.z,Gridded(Linear())))
    end
end

function area(cs::InterpolatedCrossSectionData,h,θ=0)
    cszi = cs.cszi
    Amax = cs.cs.Amax
    lmax = cs.cs.lmax
    hmax = cs.cs.hmax
    cg = cszi[cszi.knots[1]]
    if h > hmax
        return Amax + (tand(θ)*(h-hmax)+lmax)*(h-hmax)
    end
    a,b = findzeros(cszi,h)
    quadgk(x->(h-cszi[x]),a,b)[1]
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

function vavg(adcp::ADCPDataCP)
    bs = bins(adcp.dep.adcp)
    p = adcp.p
    v = adcp.v
    t = adcp.t
    tops = zeros(Int,length(p))
    for i in 1:length(p)
        q = find(x->x<p[i],bs)
        tops[i] = isempty(q) ? 0 : q[end]
    end
    vma = zeros(length(p),3)
    for i in 1:length(p)
        for j in 1:3
            r = tops[i]
            if r == 0
                vma[i,j] = 0.0
            else
                vma[i,j] = mean(v[1:r,i,j])
            end
        end
    end
    vma
end

function DischargeData.Discharge(adcp::ADCPData,cs::CrossSectionData)
    E = adcp.dep.adcp.elevation
    cd1 = atmoscorrect(adcp)
    cp = cd1.p
    ts = cd1.t
    vma = vavg(cd1)
    l,Z = eig(cov(vma))
    vs = vma*Z[:,3]
    h = E+0.01:0.01:maximum(cp)+E
    csdi = InterpolatedCrossSectionData(cs)
    Ah = map(x->area(csdi,x),h)
    X = [ones(h) h h.^2 h.^3 h.^4 h.^5]
    b = X\Ah
    A = b[1] + b[2]*(cp+E)+b[3]*(cp+E).^2+b[4]*(cp+E).^3+b[5]*(cp+E).^4+b[6]*(cp+E).^5
    Q = vs.*A
    Qi = Q.*detectOrientation(cp,Q)
    Discharge(cp,ts,vs,A,Qi)
end

# A quick, dirty and not great way to fix the sign of Q
function detectOrientation(cp::Vector{Float64},Q::Vector{Float64})
    N1 = countnz(sign(gradient(cp)) .== sign(Q))
    N2 = countnz(sign(gradient(cp)) .== sign(-Q))
    N1 > N2 ? 1.0 : -1.0
end
