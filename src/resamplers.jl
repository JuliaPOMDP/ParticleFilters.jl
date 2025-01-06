struct NormalizedESSConditionalResampler{R<:Function} <: Function
    resample::R
    threshold::Float64
end

function (re::NormalizedESSConditionalResampler)(b::AbstractParticleBelief, a, o, rng::AbstractRNG)
    ess = effective_sample_size(b)
    if ess < re.threshold*n_particles(b)
        particles = re.resample(b, a, o, rng)
        return WeightedParticleBelief(particles, ones(length(particles), length(particles)))
    else
        return b
    end
end

(re::NormalizedESSConditionalResampler)(b::ParticleCollection, a, o, rng::AbstractRNG) = b # a particle collection will never have a threshold low enough to need to be resampled
