module ParticleFilters

using POMDPs
import POMDPs: pdf, mode, update, initialize_belief, support
import POMDPs: statetype, isterminal, observation
import POMDPs: generate_s
import POMDPs: action, value
import POMDPs: implemented
import POMDPs: sampletype

import POMDPModelTools: obs_weight
using StatsBase
using Random
using Statistics
using POMDPPolicies
using POMDPModelTools # for weighted_iterator

import Random: rand
import Statistics: mean

export
    AbstractParticleBelief,
    ParticleCollection,
    WeightedParticleBelief,
    SimpleParticleFilter,
    ImportanceResampler,
    LowVarianceResampler,
    SIRParticleFilter,
    UnweightedParticleFilter

export
    resample,
    n_particles,
    particles,
    weighted_particles,
    weight_sum,
    weight,
    particle,
    weights,
    obs_weight,
    n_init_samples

export
    pdf,
    mode,
    update,
    support,
    initialize_belief

export
    generate_s,
    observation,
    isterminal,
    statetype

abstract type AbstractParticleBelief{T} end

sampletype(::Type{B}) where B<:AbstractParticleBelief{T} where T = T
Random.gentype(::Type{B}) where B<:AbstractParticleBelief{T} where T = T

### Belief types ###

"""
Unweighted particle belief
"""
mutable struct ParticleCollection{T} <: AbstractParticleBelief{T}
    particles::Vector{T}
    _probs::Union{Nothing, Dict{T,Float64}} # a cache for the probabilities

    ParticleCollection{T}() where {T} = new(T[], nothing)
    ParticleCollection{T}(particles) where {T} = new(particles, Dict{T,Float64}())
    ParticleCollection{T}(particles, _probs) where {T} = new(particles, _probs)
end
ParticleCollection(p::AbstractVector{T}) where T = ParticleCollection{T}(p, nothing)

mutable struct WeightedParticleBelief{T} <: AbstractParticleBelief{T}
    particles::Vector{T}
    weights::Vector{Float64}
    weight_sum::Float64
    _probs::Union{Nothing, Dict{T,Float64}} # this is not used now, but may be later
end
WeightedParticleBelief(particles::AbstractVector{T}, weights::AbstractVector, weight_sum=sum(weights)) where {T} = WeightedParticleBelief{T}(particles, weights, weight_sum, nothing)

### Belief interface ###
# see beliefs.jl for implementation
# also rand(), pdf(), and mode() from POMDPs.jl are part of the belief interface.
"""
    n_particles(b::AbstractParticleBelief)

Return the number of particles.
"""
function n_particles end

"""
    particles(b::AbstractParticleBelief)

Return an iterator over the particles.
"""
function particles end

"""
    weighted_particles(b::AbstractParticleBelief)

Return an iterator over particle-weight pairs.
"""
function weighted_particles end

"""
    weight_sum(b::AbstractParticleBelief)

Return the sum of the weights of the particle collection.
"""
function weight_sum end

"""
    weight(b::AbstractParticleBelief, i)

Return the weight for particle i.
"""
function weight end


"""
    particle(b::AbstractParticleBelief, i)

Return particle i.
"""
function particle end

### Basic Particle Filter ###
# implements the POMDPs.jl Updater interface
# see updater.jl for implementations
"""
    SimpleParticleFilter(model, resample, rng)

A particle filter that calculates relative weights for each particle based on observation likelihood, and then resamples.

The resample field may be a function or an object that controls resampling. If it is a function `f`, `f(b, rng)` will be called. If it is an object, `o`, `resample(o, b, rng)` will be called, where `b` is a `WeightedParticleBelief`.
"""
mutable struct SimpleParticleFilter{M,R,RNG<:AbstractRNG} <: Updater
    model::M
    resample::R
    n_init::Int
    rng::RNG
    _particle_memory::Union{Nothing,AbstractVector}
    _weight_memory::Vector{Float64}

    SimpleParticleFilter{M, R, RNG}(model, resample, n, rng) where {M,R,RNG} = new(model, resample, n, rng, nothing, Float64[])
    SimpleParticleFilter{M, R, RNG}(model::POMDP, resample, n, rng) where {M,R,RNG} = new(model, resample, n, rng, statetype(model)[], Float64[])
end
function SimpleParticleFilter(model, resample::R, rng::AbstractRNG) where {R}
    SimpleParticleFilter{typeof(model),R,typeof(rng)}(model, resample, n, rng)
end
SimpleParticleFilter(model, resample, n; rng::AbstractRNG=Random.GLOBAL_RNG) = SimpleParticleFilter(model, resample, n, rng)

function update(up::SimpleParticleFilter, b::ParticleCollection, a, o)
    ps = particles(b)
    pm = up._particle_memory
    wm = up._weight_memory
    resize!(pm, 0)
    resize!(wm, 0)
    sizehint!(pm, n_particles(b))
    sizehint!(wm, n_particles(b))
    all_terminal = true
    for i in 1:n_particles(b)
        s = ps[i]
        if !isterminal(up.model, s)
            all_terminal = false
            sp = generate_s(up.model, s, a, up.rng)
            push!(pm, sp)
            push!(wm, obs_weight(up.model, s, a, sp, o))
        end
    end

    return resample(up.resample,
                    WeightedParticleBelief(pm, wm, sum(wm), nothing),
                    up.model,
                    b, a, o,
                    up.rng)
end

function Random.seed!(f::SimpleParticleFilter, seed)
    Random.seed!(f.rng, seed)
    return f
end


isterminal(model, s) = false
observation(model, s, a, sp) = observation(model, a, sp)

### Resample Interface ###
# see resamplers.jl for implementations
"""
    resample(resampler, bp::AbstractParticleBelief, rng::AbstractRNG)

Sample a new ParticleCollection from `bp`.

Generic domain-independent resamplers should implement this version.
"""
function resample end

"""
    resample(resampler, bp::WeightedParticleBelief, model, b, a, o, rng)

Sample a new particle collection from bp with additional information from the arguments to the update function.

This version defaults to `resample(resampler, bp, rng)`. Domain-specific resamplers that wish to add noise to particles, etc. should implement this version.
"""
function resample(resampler, bp::WeightedParticleBelief, model, b, a, o, rng)
    if isempty(particles(bp)) && all(isterminal(model, s) for s in particles(b))
        error("Particle filter update error: all states in the particle collection were terminal.")
    end
    resample(resampler, bp, rng)
end

"""
    n_init_samples(resampler)

Number of samples for the initial particle collection.

This is used in the default implementation of initialize_belief.
"""
function n_init_samples end

### Resamplers ###
struct ImportanceResampler
    n::Int
end

# low variance sampling algorithm on page 110 of Probabilistic Robotics by Thrun Burgard and Fox
struct LowVarianceResampler
    n::Int
end


### Convenience Aliases ###
const SIRParticleFilter{T} = SimpleParticleFilter{T, LowVarianceResampler}

function SIRParticleFilter(model, n::Int; rng::AbstractRNG=Random.GLOBAL_RNG)
    return SimpleParticleFilter(model, LowVarianceResampler(n), n, rng)
end
function SIRParticleFilter(model, n::Int, rng::AbstractRNG)
    return SimpleParticleFilter(model, LowVarianceResampler(n), n, rng)
end


include("unweighted.jl")
include("beliefs.jl")
include("updater.jl")
include("resamplers.jl")
include("policies.jl")

end # module
