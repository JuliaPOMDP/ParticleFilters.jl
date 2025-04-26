struct ParticleFilterModel{S, F, G}
    f::F
    g::G
end

function ParticleFilterModel{S}(f::F, g::G) where {S, F<:Function, G<:Function}
    Base.depwarn("ParicleFilterModel is deprecated. Pass the functions directly to BootstrapFilter instead.", :ParticleFilterModel)
    return ParticleFilterModel{S, F, G}(f, g)
end

@deprecate BasicPredictor(m::ParticleFilterModel) BasicPredictor(m.f)

@deprecate BasicReweighter(m::ParticleFilterModel) BasicReweighter(m.g)

@deprecate BootstrapFilter(m::ParticleFilterModel, n::Integer; resample_threshold=0.9, postprocess=(bp, args...)->bp, rng::AbstractRNG=Random.default_rng()) BootstrapFilter(m.f, m.g, n; resample_threshold=resample_threshold, postprocess=postprocess, rng=rng)

@deprecate BootstrapFilter(m::ParticleFilterModel, n::Integer, rng::AbstractRNG; resample_threshold=0.9, postprocess=(bp, args...)->bp) BootstrapFilter(m.f, m.g, n; resample_threshold=resample_threshold, postprocess=postprocess, rng=rng)

@deprecate BootsrapFilter(m::POMDP, n::Integer, rng::AbstractRNG) BootstrapFilter(m, n; rng=rng)


@deprecate low_variance_resample(b::AbstractParticleBelief, n::Int, rng::AbstractRNG) low_variance_sample(b, n, rng)

struct LowVarianceResampler <: Function
    n::Int
end

function (re::LowVarianceResampler)(b::AbstractParticleBelief, a, o, rng::AbstractRNG)
    Base.depwarn("LowVarianceResampler is deprecated. Use low_variance_sample instead.", :LowVarianceResampler)
    ParticleCollection(low_variance_resample(b, re.n, rng))
end

function (re::LowVarianceResampler)(b::WeightedParticleBelief, a, o, rng::AbstractRNG)
    Base.depwarn("LowVarianceResampler is deprecated. Use low_variance_sample instead.", :LowVarianceResampler)
    WeightedParticleBelief(low_variance_resample(b, re.n, rng), ones(re.n), re.n)
end

struct ImportanceResampler <: Function
    n::Int
end

function (r::ImportanceResampler)(b::AbstractParticleBelief, a, o, rng::AbstractRNG)
    Base.depwarn("ImportanceResampler is deprecated. Simply use rand instead.", :ImportanceResampler)
    ps = Array{gentype(b)}(undef, r.n)
    if weight_sum(b) <= 0
        @warn("Invalid weights in particle filter: weight_sum = $(weight_sum(b))")
    end
    #XXX this may break if StatsBase changes
    StatsBase.alias_sample!(rng, particles(b), Weights(weights(b), weight_sum(b)), ps)
    return WeightedParticleBelief(ps, ones(r.n), r.n)
end
