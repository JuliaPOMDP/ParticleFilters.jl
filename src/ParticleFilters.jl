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

using AliasTables: AliasTable
using ReadOnlyArrays: ReadOnlyVector

export
    AbstractParticleBelief,
    ParticleCollection,
    WeightedParticleBelief,
    BasicParticleFilter,
    UnweightedParticleFilter,
    BootstrapFilter

export
    check_particle_belief,
    PostprocessChain

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
    set_weight!,
    set_pair!,
    push_pair!,
    effective_sample_size,
    low_variance_sample
    
export
    runfilter

export
    pdf,
    mode,
    update,
    support,
    initialize_belief


include("beliefs.jl")
include("basic.jl")

include("resamplers.jl")

include("unweighted.jl")
include("models.jl")
include("postprocessing.jl")
include("bootstrap.jl")
include("pomdps.jl")
include("policies.jl")
include("runfilter.jl")
include("deprecated.jl")

# deprecated
export
    low_variance_resample,
    ImportanceResampler,
    LowVarianceResampler,
    ParticleFilterModel



end # module
