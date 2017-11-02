export OBS3,
    AnalogLow,
    AnalogHigh,
    Turbidity,
    BU_obs_dict

struct OBS3
    serialNumber::String
    lowcoeffs::Vector{Float64}
    lowrange
    highcoeffs::Vector{Float64}
    highrange
end

"""
An ``R``-valued time series for low-range 
analog data
"""
@quantity AnalogLow Real

AnalogLow(adcp::ADCPData) = AnalogLow(adcp.t,get(adcp.a1))

"""
An ``R``-valued time series for high-range
analog data
"""
@quantity AnalogHigh Real

AnalogHigh(adcp::ADCPData) = AnalogHigh(adcp.t,get(adcp.a2))

"""
An ``R``-valued time series for turbidity

This is intended to be expressed in 
nephelometric turbidity units, but could
easily represent turbidity in any unit
(Quantities are generally unit agnostic)
"""
@quantity Turbidity Real

function evalobs(x,obs,islow)
    if islow
        return @evalpoly(x,
                  obs.lowcoeffs[1],
                  obs.lowcoeffs[2],
                  obs.lowcoeffs[3])
    else
        return @evalpoly(x,
                  obs.highcoeffs[1],
                  obs.highcoeffs[2],
                  obs.highcoeffs[3])
    end
end

# This is another functorial transformation of a Quantity
"""
    Turbidity(analog_low,obs)

Construct turbidity out of low range OBS3 measurements.
"""
function Turbidity(a::AnalogLow,obs::OBS3)
    aq = quantity(a)
    b = [evalobs(aq[i],obs,true) for i in eachindex(aq)]
    Turbidity(times(a),b)
end

"""
    Turbidity(analog_high,obs)

Construct turbidity out of high range OBS3 measurements
"""
function Turbidity(a::AnalogHigh,obs::OBS3)
    aq = quantity(a)
    b = [evalobs(aq[i],obs,false) for i in eachindex(aq)]
    Turbidity(times(a),b)
end

## These are the Boston University OBS sensors. I am not sure how best to
## extend these. Perhaps there should be a special BU module somewhere.
## Or a global metadata that can also store things like the data directories

BU_obs_dict = Dict(
    "T8271" => OBS3("T8271",[0.0741962;0.0456691;1.40e-6],250,[-0.1695174;0.1828727;2.30e-5],1000),
    "S7369" => OBS3("S7369",[-1.6589562;0.3550035;0.0000111],2000,[-3.5677807;1.352775;2.45e-4],4000),
    "T8514" => OBS3("T8514",[-0.9699;0.2002;4.295e-7],1000,[8.326;0.6861;1.039e-4],4000),
    "S8889" => OBS3("S8889",[-0.62093;0.17273;7.0002e-6],1000,[-2.8095;0.70793;9.9040e-5],4000),
    "S8890" => OBS3("S8890",[-0.99068;0.17358;7.1803e-6],1000,[-3.4409;0.71592;9.7884e-5],4000),
    "T9007" => OBS3("T9007",[-0.69297;0.16325;9.5139e-06],1000,[-6.8868;0.72352;9.2107e-05],4000),
    "T9190" => OBS3("T9190",[-0.55664;0.15881;9.5247e-6],1000,[-6.1996;0.69473;1.0232e-4],4000)
)
