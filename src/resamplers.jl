
# TODO: remove
# n_init_samples(r::Union{LowVarianceResampler, ImportanceResampler}) = r.n

struct NormalizedESSConditionalResampler{R} <: Function
    resampler::R
    threshold::Float64
end

function (re::NormalizedESSConditionalResampler)(b::AbstractParticleBelief, a, o, rng::AbstractRNG)
    ess = effective_sample_size(b)
    if ess < re.threshold*n_particles(b)
        return re.resampler(b, a, o, rng)
    else
        return b
    end
end
