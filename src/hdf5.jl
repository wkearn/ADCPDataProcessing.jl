using HDF5, JSON

"""
    database2HDF5(creek[, ADCPdatadir])

Convert a database entry corresponding to the given Creek into the HDF5 format.

See the documentation ([HDF5 Schema](@ref)) for the schema for the HDF5 generated by this function.
"""
function database2HDF5(creek::Creek,ADCPdatadir=TidalFluxConfigurations.config[:_ADCPDATA_DIR])
    data_dir = joinpath(ADCPdatadir,string(creek))
    md = JSON.parsefile(joinpath(data_dir,"METADATA.json"))

    h5open(joinpath(data_dir,"data.h5"),"w") do file
        attrs(file)["site-name"] = md["site-name"]

        # Create GPS group
        gps = g_create(file,"gps")
        attrs(gps)["east"] = md["gps"]["east"]
        attrs(gps)["north"] = md["gps"]["north"]
        attrs(gps)["epsg"] = md["gps"]["epsg"]

        # Create a cross-section group + data set
        csd,csh = readdlm(joinpath(data_dir,"cross-section.csv"),',',header=true)
        cs = g_create(file,"cross-section")
        # Note that these indices might not be the same for all creeks
        idxn = findin(csh,["North"])[1]
        idxe = findin(csh,["East"])[1]
        idxz = findin(csh,["Elevation"])[1]
        idxd = findin(csh,["Distance"])[1]
        cs["north"] = Vector{Float64}(csd[1:end-1,idxn])
        cs["east"]  = Vector{Float64}(csd[1:end-1,idxe])
        cs["elevation"] = Vector{Float64}(csd[1:end-1,idxz])
        cs["distance"]  = Vector{Float64}(csd[1:end-1,idxd])
        attrs(cs)["epsg"] = md["cross-section"]["epsg"]

        # Create deployments group, a group for each deployment, and datasets within each deployment group
        deps = g_create(file,"deployments")
        for dep in md["deployments"]
            dg = g_create(deps,dep["id"])
            attrs(dg)["deltaT"] = dep["deltaT"]
            attrs(dg)["hasAnalog"] = string(dep["hasAnalog"])
            if dep["hasAnalog"]
                attrs(dg)["obsSerialNumber"] = dep["obsSerialNumber"]
                attrs(dg)["validAnalog"] = string(dep["validAnalog"])
            end
            attrs(dg)["serialNumber"] = dep["serialNumber"]
            attrs(dg)["blankingDistance"] = dep["blankingDistance"]
            attrs(dg)["startDate"] = dep["startDate"]
            attrs(dg)["endDate"] = dep["endDate"]
            attrs(dg)["elevation"] = dep["elevation"]
            attrs(dg)["cellSize"] = dep["cellSize"]
            attrs(dg)["nCells"] = dep["nCells"]
            # Datasets
            A = readdlm(joinpath(data_dir,"deployments",dep["id"],"amplitudes.csv")) # reshape this
            dg["amplitude"] = reshape(A,(dep["nCells"],:,3))
            if dep["hasAnalog"]
                dg["analog1"] = vec(readdlm(joinpath(data_dir,"deployments",dep["id"],"analog1.csv")))
                dg["analog2"] = vec(readdlm(joinpath(data_dir,"deployments",dep["id"],"analog2.csv")))
            end
            dg["heading"] = vec(readdlm(joinpath(data_dir,"deployments",dep["id"],"heading.csv")))
            dg["pitch"] = vec(readdlm(joinpath(data_dir,"deployments",dep["id"],"pitch.csv")))
            dg["pressure"] = vec(readdlm(joinpath(data_dir,"deployments",dep["id"],"pressure.csv")))
            dg["roll"] = vec(readdlm(joinpath(data_dir,"deployments",dep["id"],"roll.csv")))
            dg["temperature"] = vec(readdlm(joinpath(data_dir,"deployments",dep["id"],"temperature.csv")))
            dg["time"] = Vector{String}(vec(readdlm(joinpath(data_dir,"deployments",dep["id"],"times.csv"))))
            V = readdlm(joinpath(data_dir,"deployments",dep["id"],"velocities.csv")) # reshape this
            dg["velocity"] = reshape(V,(dep["nCells"],:,3))
        end

        # Do the same thing but for calibrations
        cals = g_create(file,"calibrations")
        for cal in md["calibrations"]
            cg = g_create(cals,cal["id"])
            attrs(cg)["startDate"] = cal["startDate"]
            attrs(cg)["endDate"] = cal["endDate"]
            attrs(cg)["deployment"] = cal["deployment"] # See if we could make this into a HDF5ReferenceObject or similar

            df,dfh = readdlm(joinpath(data_dir,"calibrations",cal["id"],"discharge_calibrations.csv"),',',header=true)
            idxt,idxq = findin(dfh,["DateTime";"SP_Q"])
            cg["discharge_times"] = Vector{String}(df[:,idxt])
            cg["discharge"] = Vector{Float64}(df[:,idxq])

            if "tss_calibrations.csv" ∈ readdir(joinpath(data_dir,"calibrations",cal["id"]))
                tf,tfh = readdlm(joinpath(data_dir,"calibrations",cal["id"],"tss_calibrations.csv"),',',header=true)
                idxt,idxq = findin(tfh,["DateTime";"TSS"])
                cg["tss_times"] = Vector{String}(tf[:,idxt])
                cg["tss"] = Vector{Float64}(tf[:,idxq])
            end
        end
    end
end

"""
    h5load_data(dep[, ADCPdatadir])

Load ADCP data from the appropriate HDF5 file.
"""
function h5load_data(dep::Deployment,ADCPdatadir=TidalFluxConfigurations.config[:_ADCPDATA_DIR])
    h5file = joinpath(ADCPdatadir,string(dep.location),"data.h5")
    h5open(h5file,"r") do fid
        d = read(fid,"deployments")
        dd = d[dep.id]
        p = dd["pressure"]
        v = dd["velocity"]
        a = dd["amplitude"]
        t = DateTime.(dd["time"])
        temp = dd["temperature"]
        pitch = dd["pitch"]
        roll = dd["roll"]
        heading = dd["heading"]
        a1 = dep.adcp.hasAnalog ? Nullable{Vector{Float64}}(dd["analog1"]) : Nullable{Vector{Float64}}()
        a2 = dep.adcp.hasAnalog ? Nullable{Vector{Float64}}(dd["analog2"]) : Nullable{Vector{Float64}}()        
        ADCPData(dep,p,v,a,t,temp,pitch,roll,heading,a1,a2)
    end
end

"""
    h5load_data(cs[, ADCPdatadir])

Load cross-section data from appropriate HDF5 file.
"""
function h5load_data(cs::CrossSection,ADCPdatadir=TidalFluxConfigurations.config[:_ADCPDATA_DIR])
    h5file = joinpath(ADCPdatadir,string(cs.location),"data.h5")
    h5open(h5file,"r") do fid
        d = read(fid,"cross-section")
        X = d["distance"]
        Z = d["elevation"]
        CrossSectionData(cs,X,Z)
    end
end

function h5load_data(cal::CalibrationDeployment,ADCPdatadir=TidalFluxConfigurations.config[:_ADCPDATA_DIR])
    ad = h5load_data(cal.deployment)
    cs = load_data(cal.cs)
    _,dd = computedischarge(ad,cs)

    h5file = joinpath(ADCPdatadir,string(cal.deployment.location),"data.h5")

    h5open(h5file,"r") do fid
        d = read(fid,"calibrations")
        dt = d[cal.id]
        dc = Discharge(DateTime.(dt["discharge_times"]),dt["discharge"])
        Calibration(dc,dd)
    end
end
