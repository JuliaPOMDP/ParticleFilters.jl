struct LDResampler
    lv::LowVarianceResampler
end

LDResampler(n::Int) = LDResampler(LowVarianceResampler(n))

function ParticleFilters.resample(r::LDResampler,
                                  bp::WeightedParticleBelief,
                                  m::LightDark1D,
                                  b,
                                  a,
                                  o,
                                  rng)
    if a == 0
        return ParticleCollection([LightDark1DState(-1, 0.0)])
    end
    return resample(r.lv, bp, rng)
end

ParticleFilters.resample(r::LDResampler, d, rng::AbstractRNG) = resample(r.lv, d, rng)

@testset "domain_specific" begin

n = 100
m = LightDark1D()
up = SimpleParticleFilter(m, LDResampler(n))
p = FunctionPolicy(b->0)

bp = first(stepthrough(m, p, up, "bp"))
@test first(particles(bp)) == LightDark1DState(-1, 0.0)

p2 = FunctionPolicy(b->2)
for bp in stepthrough(m, p2, up, "bp", max_steps=3)
    @test bp isa ParticleCollection{LightDark1DState}
    @test n_particles(bp) == n
end
    
end
