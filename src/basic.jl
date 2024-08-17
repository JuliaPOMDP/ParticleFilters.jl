### Basic Particle Filter ###

"""
    BasicParticleFilter
"""
struct BasicParticleFilter{F1,F2,F3,F4,F5,RNG<:AbstractRNG} <: Updater
    initialize::F1
    preprocess::F2
    predict::F3
    reweight::F4
    postprocess::F5
    rng::RNG
end



function BasicParticleFilter(initialize, preprocess, predict, reweight, postprocess)
    return BasicParticleFilter(preprocess, predict, reweight, postprocess, Random.TaskLocalRNG())
end

function update(up::BasicParticleFilter, b::AbstractParticleBelief, a, o)
    bb = up.preprocess(b, a, o, up.rng)
    particles = up.predict(bb, a, o, up.rng)
    weights = up.reweight(bb, a, particles, o)
    bp = WeightedParticleBelief(ps, ws)
    return up.postprocess(bp, b, a, o, up.rng)
end

function Random.seed!(f::BasicParticleFilter, seed)
    Random.seed!(f.rng, seed)
    return f
end
