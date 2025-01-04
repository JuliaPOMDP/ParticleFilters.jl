module ParticleFilters

using POMDPs
import POMDPs: pdf, mode, update, initialize_belief, support
import POMDPs: statetype, isterminal, observation
import POMDPs: action, value

using POMDPLinter: @implemented

import POMDPTools.ModelTools:obs_weight
using StatsBase
using LinearAlgebra
using Random
using Statistics
using POMDPTools.Policies: AlphaVectorPolicy, alphavectors
using POMDPTools.ModelTools: weighted_iterator 

import Random: rand, gentype
import Statistics: mean, cov, var

# TODO cleanup export

export
    AbstractParticleBelief,
    ParticleCollection,
    WeightedParticleBelief,
    BasicParticleFilter,
    ImportanceResampler,
    LowVarianceResampler,
    UnweightedParticleFilter,
    ParticleFilterModel,
#     PredictModel,
    BootstrapFilter
#     ReweightModel

# export
#     resample,
#     predict,
#     predict!,
#     reweight,
#     reweight!,
#     particle_memory

export
    n_particles,
    particles,
    weighted_particles,
    weight_sum,
    weight,
    particle,
    weights,
    obs_weight,
    set_particle!,
    set_pair!,
    push_pair!,
    effective_sample_size,
    low_variance_sample,
    
#     n_init_samples,

export
    runfilter

export
    pdf,
    mode,
    update,
    support,
    initialize_belief

# deprecated
export
    SIRParticleFilter

include("beliefs.jl")
include("basic.jl")

export
    low_variance_resample

include("resamplers.jl")

include("unweighted.jl")
include("models.jl")
include("postprocessing.jl")
include("bootstrap.jl")
include("pomdps.jl")
include("policies.jl")
include("runfilter.jl")
include("deprecated.jl")

end # module
