### Basic Particle Filter ###
# implements the POMDPs.jl Updater interface


"""
    BasicParticleFilter(resample, predict, reweight, [propose], [rng::AbstractRNG])
"""
struct BasicParticleFilter{RS,PR,RW,PR,RNG<:AbstractRNG,PMEM} <: Updater
    preprocess::RS
    predict::PRE
    reweight::RW
    postprocess::PRO
    rng::RNG
end

function BasicParticleFilter(resample, predict, reweight)
    return BasicParticleFilter(resample, predict, reweight, propose, Random.TaskLocalRNG())
end

function update(up::BasicParticleFilter, b::AbstractParticleBelief, a, o)
    b_resampled = up.preprocess(b, a, o, up.rng)
    ps = up.predict(b_resampled, a, o, up.rng)
    ws = up.reweight(b_resampled, a, ps, o)
    bp = WeightedParticleBelief(ps, ws)
    new_belief = up.postprocess(bp, b, a, o, up.rng)
    return new_belief
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
