using HDF5, JSON

function database2HDF5(creek::Creek,ADCPdatadir=adcp_data_directory[:_ADCPDATA_DIR])
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
        idxn,idxe,idxz,idxd = findin(csh,["North","East","Elevation","Distance"])
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
