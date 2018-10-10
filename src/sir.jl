### Convenience Aliases ###
function SIRParticleFilter(model, n::Int; rng::AbstractRNG=Random.GLOBAL_RNG)
    return BasicParticleFilter(model, LowVarianceResampler(n), n, rng)
end
function SIRParticleFilter(model, n::Int, rng::AbstractRNG)
    return BasicParticleFilter(model, LowVarianceResampler(n), n, rng)
end
