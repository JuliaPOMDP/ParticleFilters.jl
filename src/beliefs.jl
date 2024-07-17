abstract type AbstractParticleBelief{T} end

Random.gentype(::Type{B}) where B<:AbstractParticleBelief{T} where T = T

########################
### Belief interface ###
########################

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
    ParticleCollection{S}

Unweighted particle belief consisting of equally important particles of type `S`.
"""
mutable struct ParticleCollection{T} <: AbstractParticleBelief{T}
    particles::Vector{T}
    _probs::Union{Nothing, Dict{T,Float64}} # a cache for the probabilities

    ParticleCollection{T}() where {T} = new(T[], nothing)
    ParticleCollection{T}(particles) where {T} = new(particles, nothing)
    ParticleCollection{T}(particles, _probs) where {T} = new(particles, _probs)
end
ParticleCollection(p::AbstractVector{T}) where T = ParticleCollection{T}(p, nothing)

n_particles(b::ParticleCollection) = length(b.particles)
particles(p::ParticleCollection) = p.particles
weights(b::ParticleCollection) = ones(n_particles(b))
weighted_particles(p::ParticleCollection) = (s=>1.0 for s in p.particles)
weight_sum(b::ParticleCollection) = n_particles(b)
weight(b::ParticleCollection, i::Int) = 1.0
particle(b::ParticleCollection, i::Int) = b.particles[i]
rand(rng::AbstractRNG, sampler::Random.SamplerTrivial{<:ParticleCollection}) = sampler[].particles[rand(rng, 1:length(sampler[].particles))]
support(b::ParticleCollection) = unique(particles(b))
Statistics.mean(b::ParticleCollection) = sum(b.particles) / length(b.particles)
function Statistics.cov(b::ParticleCollection{T}) where {T <: Number} # uncorrected covariance
    centralized = b.particles .- mean(b)
    centralized' * centralized / length(b.particles) # dot product
end
function Statistics.cov(b::ParticleCollection{T}) where {T <: Vector} # uncorrected covariance
    centralized = reduce(hcat, b.particles) .- mean(b)
    centralized * centralized' / length(b.particles) # outer product
end

## Weighted ##

"""
    WeightedParticleBelief{S}

Weighted particle belief consisting of particles of type `S` and their associated weights.
"""
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

function Random.rand(rng::AbstractRNG, sampler::Random.SamplerTrivial{<:WeightedParticleBelief})
    b = sampler[]
    t = rand(rng) * weight_sum(b)
    i = 1
    cw = b.weights[1]
    while cw < t && i < length(b.weights)
        i += 1
        @inbounds cw += b.weights[i]
    end
    return particles(b)[i]
end
Statistics.mean(b::WeightedParticleBelief{T}) where {T <: Number} = dot(b.weights, b.particles) / weight_sum(b)
Statistics.mean(b::WeightedParticleBelief{T}) where {T <: Vector} = reduce(hcat, b.particles) * b.weights / weight_sum(b)
function Statistics.cov(b::WeightedParticleBelief{T}) where {T <: Number} # uncorrected covariance
    centralized = b.particles .- mean(b)
    sum(centralized .* b.weights .* centralized) / weight_sum(b)
end
function Statistics.cov(b::WeightedParticleBelief{T}) where {T <: Vector} # uncorrected covariance
    centralized = reduce(hcat, b.particles) .- mean(b)
    (centralized .* b.weights') * centralized' / weight_sum(b)
end

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
Statistics.var(b::AbstractParticleBelief{T}) where {T <: Number} = cov(b)
Statistics.var(b::AbstractParticleBelief{T}) where {T <: Vector} = diag(cov(b))
