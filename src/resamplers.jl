### Resample Interface ###
"""
    resample(resampler, bp::AbstractParticleBelief, rng::AbstractRNG)

Sample a new ParticleCollection from `bp`.

Generic domain-independent resamplers should implement this version.

    resample(resampler, bp::WeightedParticleBelief, predict_model, reweight_model, b, a, o, rng)

Sample a new particle collection from bp with additional information from the arguments to the update function.

This version defaults to `resample(resampler, bp, rng)`. Domain-specific resamplers that wish to add noise to particles, etc. should implement this version.
"""
function resample end

resample(resampler, bp::WeightedParticleBelief, pm, rm, b, a, o, rng) = resample(resampler, bp, rng)

function resample(resampler, bp::WeightedParticleBelief, pm::Union{POMDP,MDP}, rm, b, a, o, rng)
    if weight_sum(bp) == 0.0 && all(isterminal(pm, s) for s in particles(b))
        error("Particle filter update error: all states in the particle collection were terminal.")
    end
    resample(resampler, bp, rng)
end

### Resamplers ###

"""
    ImportanceResampler(n)

Simple resampler. Uses alias sampling to attain O(n log(n)) performance with uncorrelated samples.
"""
struct ImportanceResampler
    n::Int
end

function resample(r::ImportanceResampler, b::AbstractParticleBelief{S}, rng::AbstractRNG) where {S}
    ps = Array{S}(undef, r.n)
    if weight_sum(b) <= 0
        @warn("Invalid weights in particle filter: weight_sum = $(weight_sum(b))")
    end
    #XXX this may break if StatsBase changes
    StatsBase.alias_sample!(rng, particles(b), Weights(weights(b), weight_sum(b)), ps)
    return ParticleCollection(ps)
end

"""
    LowVarianceResampler(n)

Low variance sampling algorithm on page 110 of Probabilistic Robotics by Thrun Burgard and Fox. O(n) runtime, correlated samples, but produces a useful low-variance set.
"""
struct LowVarianceResampler
    n::Int
end

function (re::LowVarianceResampler)(b::AbstractParticleBelief{S}, rng::AbstractRNG) where {S}
    ps = Array{S}(undef, re.n)
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
    return ParticleCollection(ps)
end

function resample(re::LowVarianceResampler, b::ParticleCollection{S}, rng::AbstractRNG) where {S}
    r = rand(rng)*n_particles(b)/re.n
    chunk = n_particles(b)/re.n
    inds = ceil.(Int, chunk*(0:re.n-1).+r)
    ps = particles(b)[inds]
    return ParticleCollection(ps)
end

n_init_samples(r::Union{LowVarianceResampler, ImportanceResampler}) = r.n
