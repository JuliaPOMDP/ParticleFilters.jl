"""
    SIRParticleFilter(model, n, [rng])

Construct a sequential importance resampling particle filter.

# Arguments
- `model`: a model for the prediction dynamics and likelihood reweighing, for example a `POMDP` or `ParticleFilterModel`
- `n::Integer`: number of particles
- `rng::AbstractRNG`: random number generator

For a more flexible particle filter structure see [`BasicParticleFilter`](@ref).
"""
function SIRParticleFilter(model, n::Int, rng::AbstractRNG)
    return BasicParticleFilter(model, LowVarianceResampler(n), n, rng)
end

function SIRParticleFilter(model, n::Int; rng::AbstractRNG=Random.GLOBAL_RNG)
#@show "SIR 17 trigerred"
    return BasicParticleFilter(model, LowVarianceResampler(n), n, rng)
end
