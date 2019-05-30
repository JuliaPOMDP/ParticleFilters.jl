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
    UnweightedParticleFilter,
    ParticleFilterModel,
    PredictModel,
    ReweightModel

export
    resample,
	resample_cem, # RpB
    predict,
    predict!,
    reweight,
    reweight!,
    particle_memory

export
    n_particles,
    particles,
    weighted_particles,
    weight_sum,
    weight,
    particle,
    weights,
    obs_weight,
    n_init_samples,
    runfilter

export
    pdf,
    mode,
    update,
	update_cem, #RpB
    support,
    initialize_belief

export
    SimpleParticleFilter


include("beliefs.jl")
include("basic.jl")
include("resamplers.jl")
include("sir.jl")
include("unweighted.jl")
include("models.jl")
include("pomdps.jl")
include("policies.jl")
include("runfilter.jl")
include("deprecated.jl")

end # module
