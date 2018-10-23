### Basic Particle Filter ###
# implements the POMDPs.jl Updater interface
"""
    BasicParticleFilter(predict_model, reweight_model, resampler, n_init::Integer, rng::AbstractRNG)
    BasicParticleFilter(model, resampler, n_init::Integer, rng::AbstractRNG)

Construct a basic particle filter with three steps: predict, reweight, and resample.

In the second constructor, `model` is used for both the prediction and reweighting.
"""
mutable struct BasicParticleFilter{PM,RM,RS,RNG<:AbstractRNG,PMEM} <: Updater
    predict_model::PM
    reweight_model::RM
    resampler::RS
    n_init::Int
    rng::RNG
    _particle_memory::PMEM
    _weight_memory::Vector{Float64}
end

## Constructors ##
function BasicParticleFilter(model, resampler, n::Integer, rng::AbstractRNG=Random.GLOBAL_RNG)
    return BasicParticleFilter(model, model, resampler, n, rng)
end

function BasicParticleFilter(pmodel, rmodel, resampler, n::Integer, rng::AbstractRNG=Random.GLOBAL_RNG)
    return BasicParticleFilter(pmodel,
                               rmodel,
                               resampler,
                               n,
                               rng,
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

function update(up::BasicParticleFilter, b::ParticleCollection, a, o)
    pm = up._particle_memory
    wm = up._weight_memory
    resize!(pm, n_particles(b))
    resize!(wm, n_particles(b))
    predict!(pm, up.predict_model, b, a, o, up.rng)
    reweight!(wm, up.reweight_model, b, a, pm, o, up.rng)

    return resample(up.resampler,
                    WeightedParticleBelief(pm, wm, sum(wm), nothing),
                    up.predict_model,
                    up.reweight_model,
                    b, a, o,
                    up.rng)
end

function Random.seed!(f::BasicParticleFilter, seed)
    Random.seed!(f.rng, seed)
    return f
end


function predict! end
function reweight! end

predict!(pm, m, b, a, o, rng) = predict!(pm, m, b, a, rng)
reweight!(wm, m, b, a, pm, o, rng) = reweight!(wm, m, b, a, pm, o)

"""
    predict(m, b, u, rng)

Simulate each of the particles in `b` forward one time step using model `m` and contol input `u` returning a vector of states.
"""
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
"""
function reweight(m, b, args...)
    wm = Vector{Float64}(undef, n_particles(b))
    reweight!(wm, m, b, args...)
    return wm
end
reweight(f::BasicParticleFilter, args...) = reweight(f.reweight_model, args...)
