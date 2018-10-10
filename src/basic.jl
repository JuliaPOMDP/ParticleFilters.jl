### Basic Particle Filter ###
# implements the POMDPs.jl Updater interface
"""
    BasicParticleFilter(predict_model, reweight_model, resampler, n_init::Integer, rng::AbstractRNG)
    BasicParticleFilter(model, resampler, n_init::Integer, rng::AbstractRNG)

Construct a basic particle filter with three steps: predict, reweight, and resample.
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

particle_memory(pmodel::POMDP) = statetype(pmodel)[]

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

predict!(pm, m, b, a, o, rng) = predict!(pm, m, b, a, rng)

function predict!(pm, m::POMDP, b, a, rng)
    all_terminal = true
    for i in 1:n_particles(b)
        s = particle(b, i)
        if isterminal(m, s)
            pm[i] = undef
        else
            all_terminal = false
            sp = generate_s(m, s, a, rng)
            pm[i] = sp
        end
    end
    if all_terminal
        error("Particle filter update error: all states in the particle collection were terminal.")
    end
end

reweight!(wm, m, b, a, pm, o, rng) = reweight!(wm, m, b, a, pm, o)

function reweight!(wm, m::POMDP, b, a, pm, o)
    for i in 1:n_particles(b)
        s = particle(b, i)
        if isterminal(m, s)
            wm[i] = 0.0
        else
            sp = pm[i]
            wm[i] = obs_weight(m, s, a, sp, o)
        end
    end
end
