@testset "HDF5 loading" begin
    d1 = adata[1]
    d2 = ADCPDataProcessing.h5load_data(deps[1])
    
    @test d1.p == d2.p
    @test d1.v == d2.v
    @test d1.t == d2.t
end
