"""
    ImportanceResampler(n)

Simple resampler. Uses alias sampling to attain O(n log(n)) performance with uncorrelated samples.
"""
struct ImportanceResampler
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
struct LowVarianceResampler
    n::Int
end

function (re::LowVarianceResampler)(b::AbstractParticleBelief, a, o, rng::AbstractRNG)
    ps = Array{gentype(b)}(undef, re.n)
    r = rand(rng)*weight_sum(b)/re.n
    c = weight(b,1)
    i = 1
    U = r
    for m in 1:re.n
        while U > c && i < n_particles(b)
            i += 1
            c += weight(b, i)
        end
        U += weight_sum(b)/re.n
        ps[m] = particles(b)[i]
    end
    return WeightedParticleBelief(ps, ones(re.n), re.n)
end

function (re::LowVarianceResampler)(b::ParticleCollection, a, o, rng::AbstractRNG)
    r = rand(rng)*n_particles(b)/re.n
    chunk = n_particles(b)/re.n
    inds = ceil.(Int, chunk*(0:re.n-1).+r)
    ps = particles(b)[inds]
    return ParticleCollection(ps)
end

n_init_samples(r::Union{LowVarianceResampler, ImportanceResampler}) = r.n
