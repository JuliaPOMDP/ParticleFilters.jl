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

function BasicParticleFilter(preprocess, predict, reweight)
    return BasicParticleFilter(preprocess, predict, reweight, postprocess, Random.TaskLocalRNG())
end

function update(up::BasicParticleFilter, b::AbstractParticleBelief, a, o)
    bb = up.preprocess(b, a, o, up.rng)
    particles = up.predict(bb, a, o, up.rng)
    weights = up.reweight(bb, a, particles, o)
    bp = WeightedParticleBelief(ps, ws)
    return up.postprocess(bp, b, a, o, up.rng)
end

function check_belief(b::AbstractParticleBelief)
    if length(particles(b)) != length(weights(b))
        @warn "Number of particles and weights do not match" length(particles(b)) length(weights(b))
    end
    if weight_sum(b) <= 0.0
        @warn "Sum of particle filter weights is not greater than zero." weight_sum(b)
    end
    if sum(weights(b)) !≈ weight_sum(b)
        @warn "Sum of particle filter weights does not match weight_sum." sum(weights(b)) weight_sum(b)
    end
end

function Random.seed!(f::BasicParticleFilter, seed)
    Random.seed!(f.rng, seed)
    return f
end
