"""
    CEMParticleFilter(model, n, [rng])

Construct a cross entropy particle filter.

# Arguments
- `model`: a model for the prediction dynamics and likelihood reweighing, for example a `POMDP` or `ParticleFilterModel`
- `n::Integer`: number of particles
- `rng::AbstractRNG`: random number generator

For a more flexible particle filter structure see [`BasicParticleFilter`](@ref).
"""
function CEMParticleFilter(model, n::Int, rng::AbstractRNG)
    return BasicParticleFilter(model, CEMResampler(n), n, rng)
end

function CEMParticleFilter(model, n::Int; rng::AbstractRNG=Random.GLOBAL_RNG)
#@show "CEM 17 trigerred"
    return BasicParticleFilter(model, CEMResampler(n), n, rng)
end
