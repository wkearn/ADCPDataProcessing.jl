@testset "Masking" begin
    d1 = adata[1]
    H = atmoscorrect(d1)
    bs = bins(d1.dep.adcp)
    tt = ADCPDataProcessing.tops(H,bs)

    # Mask Stage
    m1 = ADCPDataProcessing.depth_mask(H,bs)
    # Mask ADCPData
    m2 = ADCPDataProcessing.depth_mask(d1)
    # What masking should do
    m3 = cosd(25)*quantity(H).>bs[1]
    
    @test quantity(m1) == (tt.!=0)
    @test m1 == m2
    @test quantity(m1) == m3
end
