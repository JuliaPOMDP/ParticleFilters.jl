### Basic Particle Filter ###

"""
    BasicParticleFilter(preprocess, predict, reweight, postprocess; [rng], [initialize])

Create a basic particle filter. See the [Basic Particle Filter](@ref) section of the ParticleFilters.jl documentation for more explanation.

# Arguments

In the functions below, `b` is the belief at the beginning of the update, `a` is the action, and `o` is the observation. When present, `particles` is an `AbstractVector` of propagated particles, `bp` is the new belief after the prediciton and reweighting steps, and `bb` is the belief after the preprocessing step.

- `preprocess::Function`: Function to preprocess the belief before the prediction step. The function should have the signature `preprocess(b::AbstractParticleBelief, a, o, rng)`, and should return a new belief. The returned belief may be the same as `b` (i.e. modified in place), or a new object.
- `predict::Function`: Function to propagate the particles forward in time. The function should have the signature `predict(b::AbstractParticleBelief, a, o, rng)`, and should return an `AbstractVector` of particles.
- `reweight::Function`: Function to reweight the particles based on the observation. The function should have the signature `reweight(b::AbstractParticleBelief, a, particles, o)`, and should return an `AbstractVector` of weights.
- `postprocess::Function`: Function to postprocess the belief after the update. The function should have the signature `postprocess(bp::WeightedParticleBelief, a, o, b, bb, rng)`, and should return a new belief. The returned belief may be the same as `bp` (i.e. modified in place), or a new object.

# Keyword Arguments
- `rng::AbstractRNG=Random.default_rng()`: Random number generator.
- `initialize::Function=(d, rng)->d`: Function to initialize the belief by creating a particle belief from a distribution. This can be safely ignored in many applications, but is important in POMDPs.jl. The function should have the signature `initialize(d, rng)`, and should return a new `AbstractParticleBelief` representing distribution `d`.
"""
struct BasicParticleFilter{F1,F2,F3,F4,F5,RNG<:AbstractRNG} <: Updater
    preprocess::F1
    predict::F2
    reweight::F3
    postprocess::F4
    initialize::F5
    rng::RNG
end

function BasicParticleFilter(preprocess, predict, reweight, postprocess;
                             rng=Random.default_rng(),
                             initialize=(b,rng)->b)
    return BasicParticleFilter(preprocess, predict, reweight, postprocess, initialize, rng)
end

function update(up::BasicParticleFilter, b::AbstractParticleBelief, a, o)
    bb = up.preprocess(b, a, o, up.rng)
    particles = up.predict(bb, a, o, up.rng)
    weights = up.reweight(bb, a, particles, o)
    bp = WeightedParticleBelief(particles, weights)
    return up.postprocess(bp, a, o, b, bb, up.rng)
end

function Random.seed!(f::BasicParticleFilter, seed)
    Random.seed!(f.rng, seed)
    return f
end
