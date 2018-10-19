abstract type AbstractParticleBelief{T} end

sampletype(::Type{B}) where B<:AbstractParticleBelief{T} where T = T
Random.gentype(::Type{B}) where B<:AbstractParticleBelief{T} where T = T

########################
### Belief interface ###
########################

# also rand(), pdf(), and mode() from POMDPs.jl are part of the belief interface.
"""
    n_particles(b::AbstractParticleBelief)

Return the number of particles.
"""
function n_particles end

"""
    particles(b::AbstractParticleBelief)

Return an iterator over the particles.
"""
function particles end

"""
    weights(b::AbstractParticleBelief)

Return an iterator over the weights.
"""
function weights end

"""
    weighted_particles(b::AbstractParticleBelief)

Return an iterator over particle-weight pairs.
"""
function weighted_particles end

"""
    weight_sum(b::AbstractParticleBelief)

Return the sum of the weights of the particle collection.
"""
function weight_sum end

"""
    weight(b::AbstractParticleBelief, i)

Return the weight for particle i.
"""
function weight end


"""
    particle(b::AbstractParticleBelief, i)

Return particle i.
"""
function particle end

"""
    probdict(b::AbstractParticleBelief)

Return a dictionary mapping states to probabilities.

The probability is the normalized sum of the weights for all matching particles.

For ParticleCollection and WeightedParticleBelief, the result is cached for efficiency so the calculation is only performed the first time this is called. There is a default implementation for all AbstractParticleBeliefs, but it is inefficient (it creates a new dictionary every time). New AbstractParticleBelief implementations should provide an efficient implementation.
"""
function probdict end


#############################
### Concrete Belief types ###
#############################


## Unweighted ##

"""
Unweighted particle belief
"""
mutable struct ParticleCollection{T} <: AbstractParticleBelief{T}
    particles::Vector{T}
    _probs::Union{Nothing, Dict{T,Float64}} # a cache for the probabilities

    ParticleCollection{T}() where {T} = new(T[], nothing)
    ParticleCollection{T}(particles) where {T} = new(particles, Dict{T,Float64}())
    ParticleCollection{T}(particles, _probs) where {T} = new(particles, _probs)
end
ParticleCollection(p::AbstractVector{T}) where T = ParticleCollection{T}(p, nothing)

n_particles(b::ParticleCollection) = length(b.particles)
particles(p::ParticleCollection) = p.particles
weights(b::ParticleCollection) = ones(n_particles(b))
weighted_particles(p::ParticleCollection) = (s=>1.0/length(p.particles) for s in p.particles)
weight_sum(::ParticleCollection) = 1.0
weight(b::ParticleCollection, i::Int) = 1.0/length(b.particles)
particle(b::ParticleCollection, i::Int) = b.particles[i]
rand(rng::AbstractRNG, b::ParticleCollection) = b.particles[rand(rng, 1:length(b.particles))]
Statistics.mean(b::ParticleCollection) = sum(b.particles)/length(b.particles)
support(b::ParticleCollection) = unique(particles(b))

## Weighted ##

mutable struct WeightedParticleBelief{T} <: AbstractParticleBelief{T}
    particles::Vector{T}
    weights::Vector{Float64}
    weight_sum::Float64
    _probs::Union{Nothing, Dict{T,Float64}} # this is not used now, but may be later
end
WeightedParticleBelief(particles::AbstractVector{T}, weights::AbstractVector, weight_sum=sum(weights)) where {T} = WeightedParticleBelief{T}(particles, weights, weight_sum, nothing)

n_particles(b::WeightedParticleBelief) = length(b.particles)
particles(p::WeightedParticleBelief) = p.particles
weighted_particles(b::WeightedParticleBelief) = (b.particles[i]=>b.weights[i] for i in 1:length(b.particles))
weight_sum(b::WeightedParticleBelief) = b.weight_sum
weight(b::WeightedParticleBelief, i::Int) = b.weights[i]
particle(b::WeightedParticleBelief, i::Int) = b.particles[i]
weights(b::WeightedParticleBelief) = b.weights

function Random.rand(rng::AbstractRNG, b::WeightedParticleBelief)
    t = rand(rng) * weight_sum(b)
    i = 1
    cw = b.weights[1]
    while cw < t && i < length(b.weights)
        i += 1
        @inbounds cw += b.weights[i]
    end
    return particles(b)[i]
end
Statistics.mean(b::WeightedParticleBelief) = dot(b.weights, b.particles)/weight_sum(b)

### Shared implementations ###
function probdict(b::AbstractParticleBelief{S}) where {S}
    probs = Dict{S, Float64}()
    for (i,p) in enumerate(particles(b))
        if haskey(probs, p)
            probs[p] += weight(b, i)/weight_sum(b)
        else
            probs[p] = weight(b, i)/weight_sum(b)
        end
    end
    return probs
end

function probdict(b::Union{WeightedParticleBelief{S}, ParticleCollection{S}}) where {S}
    if b._probs == nothing
        # update the cache
        probs = Dict{S, Float64}()
        for (i,p) in enumerate(particles(b))
            if haskey(probs, p)
                probs[p] += weight(b, i)/weight_sum(b)
            else
                probs[p] = weight(b, i)/weight_sum(b)
            end
        end
        b._probs = probs
    end
    return b._probs
end


pdf(b::AbstractParticleBelief{S}, s::S) where {S} = get(probdict(b), s, 0.0)

mode(b::AbstractParticleBelief) = argmax(probdict(b)) # don't know if this is the most efficient way
support(b::AbstractParticleBelief) = keys(probdict(b))
