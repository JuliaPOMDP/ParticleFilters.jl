__precompile__()

module ParticleFilters

using POMDPs
import POMDPs: pdf, mode, update, initialize_belief
import POMDPs: state_type, isterminal, observation
import POMDPs: generate_s
import POMDPs: implemented
import Base: rand, mean, eltype

export
    AbstractParticleBelief,
    ParticleCollection,
    WeightedParticleBelief,
    SimpleParticleFilter,
    ImportanceResampler,
    LowVarianceResampler,
    SIRParticleFilter

export
    resample,
    n_particles,
    particles,
    weight_sum,
    weight,
    weights,
    obs_weight

export
    pdf,
    mode,
    update,
    initialize_belief

export
    generate_s,
    observation,
    isterminal,
    state_type

abstract AbstractParticleBelief{T}
Base.eltype{T}(::Type{AbstractParticleBelief{T}}) = T

### Belief types ###

"""
Unweighted particle belief
"""
immutable ParticleCollection{T} <: AbstractParticleBelief{T}
    particles::Vector{T}
    _probs::Nullable{Dict{T,Float64}} # this is not used now, but may be later

    ParticleCollection() = new(T[], nothing)
    ParticleCollection(particles) = new(particles, Nullable{Dict{T,Float64}}())
    ParticleCollection(particles, _probs) = new(particles, _probs)
end
ParticleCollection{T}(p::AbstractVector{T}) = ParticleCollection{T}(p, nothing)

immutable WeightedParticleBelief{T} <: AbstractParticleBelief{T}
    particles::Vector{T}
    weights::Vector{Float64}
    weight_sum::Float64
    _probs::Nullable{Dict{T,Float64}} # this is not used now, but may be later
end
WeightedParticleBelief{T}(particles::AbstractVector{T}, weights::AbstractVector, weight_sum=sum(weights)) = WeightedParticleBelief{T}(particles, weights, weight_sum, nothing)

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

Return a vector of the particles.
"""
function particles end

"""
    weight_sum(b::AbstractParticleBelief)

Return the sum of the withs of the particle collection.
"""
function weight_sum end

"""
    weight(b::AbstractParticleBelief, i)

Return the weight for particle i.
"""
function weight end

"""
    obs_weight(pomdp, sp, o)
    obs_weight(pomdp, a, sp, o)
    obs_weight(pomdp, s, a, sp, o)

Return a weight proportional to the likelihood of receiving observation o from state sp (and a and s if they are present). 
"""
function obs_weight end # implemented in obs_weight

### Basic Particle Filter ###
# implements the POMDPs.jl Updater interface
# see updater.jl for implementations
"""
    SimpleParticleFilter

A particle filter that calculates relative weights for each particle based on observation likelihood, and then resamples.

The resample field may be a function or an object that controls resampling. If it is a function `f`, `f(b, rng)` will be called. If it is an object, `o`, `resample(o, b, rng)` will be called, where `b` is a `WeightedParticleBelief`.
"""
type SimpleParticleFilter{S,R} <: Updater{ParticleCollection{S}}
    model
    resample::R
    rng::AbstractRNG
    _particle_memory::Vector{S}
    _weight_memory::Vector{Float64}

    SimpleParticleFilter(model, resample, rng) = new(model, resample, rng, state_type(model)[], Float64[])
end
function SimpleParticleFilter{R}(model, resample::R, rng::AbstractRNG)
    SimpleParticleFilter{state_type(model),R}(model, resample, rng)
end
SimpleParticleFilter(model, resample; rng::AbstractRNG=Base.GLOBAL_RNG) = SimpleParticleFilter(model, resample, rng)

function update{S}(up::SimpleParticleFilter{S}, b::ParticleCollection, a, o)
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
    if all_terminal
        error("Particle filter update error: all states in the particle collection were terminal.")
        # TODO: create a mechanism to handle this failure
    end
    return resample(up.resample, WeightedParticleBelief{S}(pm, wm, sum(wm), nothing), up.rng)
end


# default for non-POMDPs
state_type(model) = Any
isterminal(model, s) = false
observation(model, s, a, sp) = observation(model, a, sp)

### Resamplers ###
immutable ImportanceResampler
    n::Int
end

# low variance sampling algorithm on page 110 of Probabilistic Robotics by Thrun Burgard and Fox
immutable LowVarianceResampler
    n::Int
end

### Resample Interface ###
# see resamplers.jl for implementations
"""
    resample(resampler, b::WeightedParticleBelief, rng::AbstractRNG)

Sample a new ParticleCollection from b.
"""
function resample end

### Convenience Aliases ###
typealias SIRParticleFilter{T} SimpleParticleFilter{T, ImportanceResampler}

function SIRParticleFilter(model, n::Int; rng::AbstractRNG=Base.GLOBAL_RNG)
    return SimpleParticleFilter(model, ImportanceResampler(n), rng)
end

include("beliefs.jl")
include("updater.jl")
include("resamplers.jl")
include("alias_sample.jl")
include("obs_weight.jl")

end # module
