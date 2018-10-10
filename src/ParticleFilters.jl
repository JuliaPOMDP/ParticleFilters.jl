__precompile__()

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
    BasicParticleFilter,
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


include("beliefs.jl")
include("basic.jl")

### Resample Interface ###
# see resamplers.jl for implementations
"""
    resample(resampler, bp::AbstractParticleBelief, rng::AbstractRNG)

Sample a new ParticleCollection from `bp`.

Generic domain-independent resamplers should implement this version.
"""
function resample end

"""
    resample(resampler, bp::WeightedParticleBelief, predict_model, reweight_model, b, a, o, rng)

Sample a new particle collection from bp with additional information from the arguments to the update function.

This version defaults to `resample(resampler, bp, rng)`. Domain-specific resamplers that wish to add noise to particles, etc. should implement this version.
"""
resample(resampler, bp::WeightedParticleBelief, pm, rm, b, a, o, rng) = resample(resampler, bp, rng)

function resample(resampler, bp::WeightedParticleBelief, pm::Union{POMDP,MDP}, rm, b, a, o, rng)
    if isempty(particles(bp)) && all(isterminal(model, s) for s in particles(b))
        error("Particle filter update error: all states in the particle collection were terminal.")
    end
    resample(resampler, bp, rng)
end

### Resamplers ###
struct ImportanceResampler
    n::Int
end

# low variance sampling algorithm on page 110 of Probabilistic Robotics by Thrun Burgard and Fox
struct LowVarianceResampler
    n::Int
end


### Convenience Aliases ###
function SIRParticleFilter(model, n::Int; rng::AbstractRNG=Random.GLOBAL_RNG)
    return BasicParticleFilter(model, LowVarianceResampler(n), n, rng)
end
function SIRParticleFilter(model, n::Int, rng::AbstractRNG)
    return BasicParticleFilter(model, LowVarianceResampler(n), n, rng)
end


include("unweighted.jl")
include("updater.jl")
include("resamplers.jl")
include("policies.jl")

end # module
