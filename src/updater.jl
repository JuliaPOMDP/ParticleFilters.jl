# this file contains functions for the POMDPs Updater interface.

initialize_belief(up::SimpleParticleFilter, b::ParticleCollection) = b

function initialize_belief(up::SimpleParticleFilter, b::WeightedParticleBelief)
    return resample(up.resample, b, up.rng)
end

function initialize_belief(up::SimpleParticleFilter, b::AbstractVector)
    pc = ParticleCollection(b)
    return resample(up.resample, pc, up.rng)
end

function initialize_belief(up::SimpleParticleFilter, d::Any)
    return resample(up.resample, d, up.rng)
end
