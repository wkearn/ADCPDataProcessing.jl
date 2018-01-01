@testset "Masking" begin
    d1 = adata[1]
    H = atmoscorrect(d1)
    bs = bins(d1.dep.adcp)
    tt = ADCPDataProcessing.tops(H,bs)

    # Mask Stage
    m1 = ADCPDataProcessing.mask(H,bs)
    # Mask ADCPData
    m2 = ADCPDataProcessing.mask(d1)
    # What masking should do
    m3 = cosd(25)*quantity(H).>bs[1]
    
    @test m1 == (tt.!=0)
    @test m1 == m2
    @test m1 == m3
end
