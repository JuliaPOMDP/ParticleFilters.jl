function light_dark_resample(bp, a, args...)
    if a == 0
        return ParticleCollection([LightDark1DState(-1, 0.0)])
    else
        return bp
    end
end


@testset "domain_specific" begin

n = 100
m = LightDark1D()
up = BootstrapFilter(m, n, postprocess=light_dark_resample)
p = FunctionPolicy(b->0)

bp = first(stepthrough(m, p, up, "bp"))
@test first(particles(bp)) == LightDark1DState(-1, 0.0)

p2 = FunctionPolicy(b->2)
for bp in stepthrough(m, p2, up, "bp", max_steps=3)
    @test bp isa AbstractParticleBelief{LightDark1DState}
    @test n_particles(bp) == n
end

end
