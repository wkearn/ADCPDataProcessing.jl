# A schema for a TidalFluxes database
# JSON schema validation provided by
# python's jsonschema

using JSON

# using PyCall, JSON
# @pyimport jsonschema

##################################################################
# Validating METADATA.json

const metadataschema=Pkg.dir("ADCPDataProcessing",
                             "src",
                             "metadataschema.json")

# function validate(instance,schema)
#     try
#         jsonschema.validate(instance,schema)==nothing
#     catch y
#         error("JSON validation error: ",y.val[:message])
#     end
# end

validate(instance,schema) = true

function validatedload(file::String,schema=metadataschema)
    schema_json = JSON.parsefile(schema)
    instance = JSON.parsefile(file)
    if validate(instance,schema_json)
        return instance
    end
end

function metadataload(creek::Creek,ADCPdatadir=TidalFluxConfigurations.config[:_ADCPDATA_DIR],schema=metadataschema)
    file = joinpath(ADCPdatadir,string(creek),"METADATA.json")
    validatedload(file)
end

##################################################################
