@testset "HDF5 ADCP data" begin
    d1 = adata[1]
    d2 = ADCPDataProcessing.h5load_data(deps[1])
    
    @test d1.p == d2.p
    @test d1.v == d2.v
    @test d1.t == d2.t
end

@testset "HDF5 cross section data" begin
    csd2 = ADCPDataProcessing.h5load_data(cs)
    @test csd.x == csd2.x
    @test csd.z == csd2.z
end
