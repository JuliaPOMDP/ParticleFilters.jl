### Basic Particle Filter ###

"""
    BasicParticleFilter
"""
struct BasicParticleFilter{F1,F2,F3,F4,F5,RNG<:AbstractRNG} <: Updater
    preprocess::F1
    predict::F2
    reweight::F3
    postprocess::F4
    initialize::F5
    rng::RNG
end

function BasicParticleFilter(preprocess, predict, reweight, postprocess;
                             rng=Random.default_rng(),
                             initialize=(b,rng)->b)
    return BasicParticleFilter(preprocess, predict, reweight, postprocess, initialize, rng)
end

function update(up::BasicParticleFilter, b::AbstractParticleBelief, a, o)
    bb = up.preprocess(b, a, o, up.rng)
    particles = up.predict(bb, a, o, up.rng)
    weights = up.reweight(bb, a, particles, o)
    bp = WeightedParticleBelief(particles, weights)
    return up.postprocess(bp, bb, a, o, up.rng) # TODO XXX should this also have bb as an arg? (bp, a, o, b, bb, up.rng)
end

function Random.seed!(f::BasicParticleFilter, seed)
    Random.seed!(f.rng, seed)
    return f
end
