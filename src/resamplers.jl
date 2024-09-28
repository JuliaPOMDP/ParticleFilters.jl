"""
    ImportanceResampler(n)

Simple resampler. Uses alias sampling to attain O(n log(n)) performance with uncorrelated samples.
"""
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

"""
    LowVarianceResampler(n)

Low variance sampling algorithm on page 110 of Probabilistic Robotics by Thrun Burgard and Fox. O(n) runtime, correlated samples, but produces a useful low-variance set.
"""
struct LowVarianceResampler <: Function
    n::Int
end


function low_variance_resample(b::AbstractParticleBelief, n::Int, rng::AbstractRNG)
    ps = Array{gentype(b)}(undef, n)
    r = rand(rng)*weight_sum(b)/n
    c = weight(b,1)
    i = 1
    U = r
    for m in 1:n
        while U > c && i < n_particles(b)
            i += 1
            c += weight(b, i)
        end
        U += weight_sum(b)/n
        ps[m] = particles(b)[i]
    end
    return ps
end

function low_variance_resample(b::ParticleCollection, n::Int, rng::AbstractRNG)
    r = rand(rng)*n_particles(b)/n
    chunk = n_particles(b)/n
    inds = ceil.(Int, chunk*(0:n-1).+r)
    return particles(b)[inds]
end

(re::LowVarianceResampler)(b::AbstractParticleBelief, a, o, rng::AbstractRNG) = ParticleCollection(low_variance_resample(b, re.n, rng))

(re::LowVarianceResampler)(b::WeightedParticleBelief, a, o, rng::AbstractRNG) = WeightedParticleBelief(low_variance_resample(b, re.n, rng), ones(re.n), re.n)

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
