### Basic Particle Filter ###
# implements the POMDPs.jl Updater interface
"""
    BasicParticleFilter(predict_model, reweight_model, resampler, n_init::Integer, rng::AbstractRNG, resampling_threshold::Float64)
    BasicParticleFilter(model, resampler, n_init::Integer, rng::AbstractRNG, resampling_threshold::Float64)

Construct a basic particle filter with three steps: predict, reweight, and resample.

In the second constructor, `model` is used for both the prediction and reweighting.

The default value for `resampling_threshold` is set to 0.9.
"""
mutable struct BasicParticleFilter{PM,RM,RS,RNG<:AbstractRNG,PMEM} <: Updater
    predict_model::PM
    reweight_model::RM
    resampler::RS
    n_init::Int
    rng::RNG
    resampling_threshold::Float64
    _particle_memory::PMEM
    _weight_memory::Vector{Float64}
end

## Constructors ##
function BasicParticleFilter(model, resampler, n::Integer, rng::AbstractRNG=Random.GLOBAL_RNG, resampling_threshold::Float64=0.9)
    return BasicParticleFilter(model, model, resampler, n, rng, resampling_threshold)
end


function BasicParticleFilter(pmodel, rmodel, resampler, n::Integer, rng::AbstractRNG=Random.GLOBAL_RNG, resampling_threshold::Float64=0.9)
    return BasicParticleFilter(pmodel,
                               rmodel,
                               resampler,
                               n,
                               rng,
                               resampling_threshold,
                               particle_memory(pmodel),
                               Float64[]
                              )
end

"""
    particle_memory(m)

Return a suitable container for particles produced by prediction model `m`.

This should usually be an empty `Vector{S}` where `S` is the type of the state for prediction model `m`. Size does not matter because `resize!` will be called appropriately within `update`.
"""
function particle_memory end

function update(up::BasicParticleFilter, b::AbstractParticleBelief, a, o)
    pm = up._particle_memory
    wm = up._weight_memory
    if normalized_ess(wm) < up.resampling_threshold
        resampled_particle_collection = resample(
            up.resampler,
            WeightedParticleBelief(pm, wm, sum(wm), nothing),
            up.predict_model,
            up.reweight_model,
            b, a, o,
            up.rng)
        num_particles = n_particles(resampled_particle_collection)
        b = WeightedParticleBelief(resampled_particle_collection.particles, fill(1.0 / num_particles, num_particles))
    end
    resize!(pm, n_particles(b))
    resize!(wm, n_particles(b))
    predict!(pm, up.predict_model, b, a, o, up.rng)
    reweight!(wm, up.reweight_model, b, a, pm, o, up.rng)
    return WeightedParticleBelief(copy(pm), copy(wm), sum(wm), nothing)
end

function Random.seed!(f::BasicParticleFilter, seed)
    Random.seed!(f.rng, seed)
    return f
end

"""
    predict!(pm, m, b, u, rng)
    predict!(pm, m, b, u, y, rng)

Fill `pm` with predicted particles for the next time step.

A method of this function should be implemented by prediction models to be used in a [`BasicParticleFilter`](@ref). `pm` should be a correctly-sized vector created by [`particle_memory`](@ref) to hold a one-step-propagated particle for each particle in `b`.

Normally the observation `y` is not needed, so most prediction models should implement the first version, but the second is available for heuristics that use `y`.

# Arguments
- `pm::Vector`: memory for holding the propagated particles; created by [`particle_memory`](@ref) and resized to `n_particles(b)`.
- `m`: prediction model, the "owner" of this function
- `b::ParticleCollection`: current belief; each particle in this belief should be propagated one step and inserted into `pm`.
- `u`: control or action
- `rng::AbstractRNG`: random number generator; should be used for any randomness in propagation for reproducibility.
- `y`: measuerement/observation (usually not needed)
"""
function predict! end

"""
    reweight!(wm, m, b, a, pm, y)
    reweight!(wm, m, b, a, pm, y, rng)

Fill `wm` likelihood weights for each particle in `pm`.

A method of this function should be implemented by reweighting models to be used in a [`BasicParticleFilter`](@ref). `wm` should be a correctly-sized vector to hold weights for each particle in pm.

Normally `rng` is not needed, so most reweighting models should implement the first version, but the second is available for heuristics that use random numbers.

# Arguments
- `wm::Vector{Float64}`: memory for holding likelihood weights.
- `m`: reweighting model, the "owner" of this function
- `b::ParticleCollection`: previous belief; `pm` should contain a propagated particle for each particle in this belief
- `u`: control or action
- `pm::Vector`: memory for holding current particles; these particle have been propagated by `predict!`.
- `y`: measurement/observation
- `rng::AbstractRNG`: random number generator; should be used for any randomness for reproducibility.
"""
function reweight! end

predict!(pm, m, b, a, o, rng) = predict!(pm, m, b, a, rng)
reweight!(wm, m, b, a, pm, o, rng) = reweight!(wm, m, b, a, pm, o)

"""
    predict(m, b, u, rng)

Simulate each of the particles in `b` forward one time step using model `m` and contol input `u` returning a vector of states. Calls [`predict!`](@ref) internally - see that function for documentation.

This function is provided for convenience only. New models should implement `predict!`.
"""
function predict end

function predict(m, b, args...)
    pm = particle_memory(m)
    resize!(pm, n_particles(b))
    predict!(pm, m, b, args...)
    return pm
end
predict(f::BasicParticleFilter, args...) = predict(f.predict_model, args...)

"""
    reweight(m, b, u, pm, y)

Return a vector of likelihood weights for each particle in `pm` given observation `y`.

`pm` can be generated with `predict(m, b, u, rng)`.

This function is provided for convenience only - new reweighting models should implement `reweight!`.
"""
function reweight end

function reweight(m, b, args...)
    wm = Vector{Float64}(undef, n_particles(b))
    reweight!(wm, m, b, args...)
    return wm
end
reweight(f::BasicParticleFilter, args...) = reweight(f.reweight_model, args...)

function normalized_ess(weights)
    num_particles = length(weights)
    normalized_weights = weights ./ sum(weights) 
    ess = 1.0 / sum(normalized_weights .^ 2) / num_particles
    return ess
end