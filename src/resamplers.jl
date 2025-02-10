struct NormalizedESSConditionalResampler{R<:Function} <: Function
    resample::R
    n::Int
    threshold::Float64
end

function (re::NormalizedESSConditionalResampler)(b::AbstractParticleBelief, a, o, rng::AbstractRNG)
    ess = effective_sample_size(b)
    if ess < re.threshold*re.n
        particles = re.resample(b, re.n, rng)
        return WeightedParticleBelief(particles, ones(length(particles)), length(particles))
    else
        return b
    end
end

function (re::NormalizedESSConditionalResampler)(b::ParticleCollection, a, o, rng::AbstractRNG)
    if n_particles(b) < re.threshold*re.n
        particles = re.resample(b, re.n, rng)
        return ParticleCollection(particles)
    else
        return b
    end
end

