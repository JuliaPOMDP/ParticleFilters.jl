# this file contains functions for the POMDPs Updater interface.

# all of the lines with resample should be changed to rand(rng, d, 3) when that becomes part of the POMDPs.jl standard

function initialize_belief(up::SimpleParticleFilter, b::AbstractParticleBelief)
    return resample(ImportanceResampler(up.n_init), b, up.rng) # resample is needed to control number of particles
end

function initialize_belief(up::SimpleParticleFilter, b::AbstractVector)
    pc = ParticleCollection(b)
    return resample(ImportanceResampler(up.n_init), pc, up.rng)
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
        return resample(ImportanceResampler(up.n_init), WeightedParticleBelief(particles, weights), up.rng)
    else
        return ParticleCollection(collect(rand(up.rng, d) for i in 1:up.n_init))
    end
end
