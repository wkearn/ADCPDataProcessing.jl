export setADCPdatadir!, data_directories

adcp_data_directory = Dict(:_ADCPDATA_DIR=>"")
                        
function setADCPdatadir!(path,datavars=adcp_data_directory)
    datavars[:_ADCPDATA_DIR] = path
end
