# this file contains functions for the POMDPs Updater interface.

function initialize_belief(up::SimpleParticleFilter, b::AbstractParticleBelief)
    n = n_init_samples(up.resample)
    return resample(ImportanceResampler(n), b, up.rng) # resample is needed to control number of particles
end

function initialize_belief(up::SimpleParticleFilter, b::AbstractVector)
    pc = ParticleCollection(b)
    n = n_init_samples(up.resample)
    return resample(ImportanceResampler(n), pc, up.rng)
end

function initialize_belief(up::SimpleParticleFilter, d::D) where D
    # using weighted iterator here is more likely to be order n than just calling rand() repeatedly
    # but, this implementation may change in the future
    if @implemented(support(::D)) && @implemented(pdf(::D, ::typeof(first(support(d)))))
        S = typeof(first(support(d)))
        particles = S[]
        weights = Float64[]
        for (s, w) in weighted_iterator(d)
            push!(particles, s)
            push!(weights, w)
        end
        n = n_init_samples(up.resample)
        return resample(ImportanceResampler(n), WeightedParticleBelief(particles, weights), up.rng)
    else
        n = n_init_samples(up.resample)
        return ParticleCollection(collect(rand(up.rng, d) for i in 1:n))
    end
end

function initialize_belief(up::SimpleParticleFilter{<:Any,<:Any,R}, d) where R <: Function
    return up.resample(d, up.rng)
end
