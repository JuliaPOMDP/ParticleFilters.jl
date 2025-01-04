function BootstrapFilter(m::ParticleFilterModel, n::Int; resample_threshold=0.9, postprocess=(bp, args...)->bp, rng::AbstractRNG=Random.default_rng())
    return BasicParticleFilter(
        NormalizedESSConditionalResampler(LowVarianceResampler(n), resample_threshold),
        BasicPredictor(m),
        BasicReweighter(m),
        PostprocessChain(postprocess, check_particle_belief),
        initialize=(d, rng)->initialize_to(WeightedParticleBelief, n, d, rng),
        rng=rng
    )
end

@deprecate low_variance_resample(b::AbstractParticleBelief, n::Int, rng::AbstractRNG) = low_variance_sample(b, n, rng)

struct LowVarianceResampler <: Function
    n::Int
end

(re::LowVarianceResampler)(b::AbstractParticleBelief, a, o, rng::AbstractRNG) = ParticleCollection(low_variance_resample(b, re.n, rng))

(re::LowVarianceResampler)(b::WeightedParticleBelief, a, o, rng::AbstractRNG) = WeightedParticleBelief(low_variance_resample(b, re.n, rng), ones(re.n), re.n)

struct ImportanceResampler <: Function
    n::Int
end

function (r::ImportanceResampler)(b::AbstractParticleBelief, a, o, rng::AbstractRNG)
    ps = Array{gentype(b)}(undef, r.n)
    if weight_sum(b) <= 0
        @warn("Invalid weights in particle filter: weight_sum = $(weight_sum(b))")
    end
    #XXX this may break if StatsBase changes
    StatsBase.alias_sample!(rng, particles(b), Weights(weights(b), weight_sum(b)), ps)
    return WeightedParticleBelief(ps, ones(r.n), r.n)
end


