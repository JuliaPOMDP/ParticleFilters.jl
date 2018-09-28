# this file contains functions for the POMDPs Updater interface.

function initialize_belief(up::SimpleParticleFilter, b::ParticleCollection)
    return resample(up.resample, b, up.rng) # resample is needed to control number of particles
end

function initialize_belief(up::SimpleParticleFilter, b::WeightedParticleBelief)
    return resample(up.resample, b, up.rng)
end

function initialize_belief(up::SimpleParticleFilter, b::AbstractVector)
    pc = ParticleCollection(b)
    return resample(up.resample, pc, up.rng)
end

function initialize_belief(up::SimpleParticleFilter, d::D) where D
    if @implemented(support(::D)) && @implemented(pdf(::D, ::typeof(first(support(d)))))
        S = typeof(first(support(d)))
        particles = S[]
        weights = Float64[]
        for (s, w) in weighted_iterator(d)
            push!(particles, s)
            push!(weights, w)
        end
        return resample(up.resample, WeightedParticleBelief(particles, weights), rng)
    else
        n = n_init_samples(up.resample)
        return ParticleCollection(collect(rand(rng, d) for i in 1:n))
    end
end

function initialize_belief(up::SimpleParticleFilter{<:Any,<:Any,R}, d) where R <: Function
    return up.resample(d, up.rng)
end
