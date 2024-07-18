struct LDResampler
    lv::LowVarianceResampler
end

LDResampler(n::Int) = LDResampler(LowVarianceResampler(n))

ParticleFilters.n_init_samples(r::LDResampler) = n_init_samples(r.lv)

function ParticleFilters.resample(r::LDResampler,
                                  bp::WeightedParticleBelief,
                                  pm::LightDark1D,
                                  rm::LightDark1D,
                                  b,
                                  a,
                                  o,
                                  rng)
    if a == 0
        return ParticleCollection([LightDark1DState(-1, 0.0)])
    end
    return resample(r.lv, bp, rng)
end


@testset "domain_specific" begin

n = 100
m = LightDark1D()
up = BasicParticleFilter(m, LDResampler(n), n)
p = FunctionPolicy(b->0)

bp = first(stepthrough(m, p, up, "bp"))
@test first(particles(bp)) == LightDark1DState(-1, 2.2388298552014967)

p2 = FunctionPolicy(b->2)
up2 = BasicParticleFilter(m, LDResampler(n), n)
for bp in stepthrough(m, p2, up2, "bp", max_steps=3)
    @test bp isa WeightedParticleBelief{LightDark1DState}
    @test n_particles(bp) == n
end

end
