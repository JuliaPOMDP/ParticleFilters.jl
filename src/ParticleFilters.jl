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


include("beliefs.jl")
include("basic.jl")
include("resamplers.jl")
include("sir.jl")
include("unweighted.jl")
include("updater.jl")
include("policies.jl")

end # module
