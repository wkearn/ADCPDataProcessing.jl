export setADCPdatadir!, setmetdatadir!, data_directories

data_directories = Dict(:_ADCPDATA_DIR=>"",
                        :_METDATA_DIR=>"")
                        

function setADCPdatadir!(path,datavars=data_directories)
    datavars[:_ADCPDATA_DIR] = path
end

function setmetdatadir!(path,datavars=data_directories)
    datavars[:_METDATA_DIR] = path
end
