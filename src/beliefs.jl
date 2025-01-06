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
    set_particle!(b::AbstractParticleBelief, i, s)

Change the particle at index i without changing the weight.

This may not work for beliefs with immutable particle storage.

# Example
```julia
set_particle!(b, 3, s)
```
"""
function set_particle! end

"""
    set_weight!(b::AbstractParticleBelief, i, w)

Change the weight at index i without changing the particle.
"""
function set_weight! end

"""
    set_pair!(b::AbstractParticleBelief{S}, i, sw::Pair{S,Float64})

Change both the particle and weight at index i. This will also adjust the weight sum appropriately.

# Example
```julia
set_pair!(b, 3, s=>0.5)
```
"""
function set_pair! end

# TODO: document
"""
    push_pair!(b::AbstractParticleBelief{S}, sw::Pair{S,Float64})

"""
function push_pair! end

"""
    probdict(b::AbstractParticleBelief)

Return a dictionary mapping states to probabilities.

The probability is the normalized sum of the weights for all matching particles.

For ParticleCollection and WeightedParticleBelief, the result is cached for efficiency so the calculation is only performed the first time this is called. There is a default implementation for all AbstractParticleBeliefs, but it is inefficient (it creates a new dictionary every time). New AbstractParticleBelief implementations should provide an efficient implementation.
"""
function probdict end

"""
    effective_sample_size(b::AbstractParticleBelief)

Calculate the effective sample size of a particle belief.

The effective sample size is ``1/\\sum_i \\hat{w}_i^2`` where ``\\hat{w}_i = w_i / \\sum_i w_i``.
"""
function effective_sample_size(b::AbstractParticleBelief)
    ws = weight_sum(b)
    return 1.0 / sum(w->(w/ws)^2, weights(b))
end

"""
    low_variance_sample(b::AbstractParticleBelief, n[, rng])

Sample n particles according to their weights using the "low variance" sampling algorithm on page 110 of Probabilistic Robotics by Thrun Burgard and Fox. O(n) runtime, correlated samples, but produces a useful low-variance set.
"""
function low_variance_sample end


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

function set_particle!(b::ParticleCollection, i, s)
    b.particles[i] = s
end

function set_weight!(b::ParticleCollection, i, w)
    @assert isapprox(w, 1.0)
end

function set_pair!(b::ParticleCollection, i, sw)
    @assert isapprox(last(sw), 1.0)
    new = first(sw)
    old = particle(b, i)
    b.particles[i] = new
    if !isnothing(b._probs)
        fraction = 1/n_particles(b)
        b._probs[old] -= fraction
        b._probs[new] = get(b._probs, new, 0.0) + fraction
    end
    return sw
end

function push_pair!(b::ParticleCollection, sw)
    @assert isapprox(last(sw), 1.0)
    new = first(sw)
    push!(b.particles, new)
    if !isnothing(b._probs)
        # the probabilities of all other states get "taxed" to pay for the new state
        fraction_kept_after_tax = (n_particles(b) - 1) / n_particles(b)
        for (s, p) in b._probs
            b._probs[s] = p * fraction_kept_after_tax
        end
        fraction = 1/n_particles(b)
        b._probs[new] = get(b._probs, new, 0.0) + fraction
        # TODO make sure to test that these updates are consistent (i.e. the probabilities sum to 1)
    end
    return b
end

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

function low_variance_sample(b::ParticleCollection, n::Int, rng::AbstractRNG=Random.default_rng())
    r = rand(rng)*n_particles(b)/n
    chunk = n_particles(b)/n
    inds = ceil.(Int, chunk*(0:n-1).+r)
    return particles(b)[inds]
end

effective_sample_size(b::ParticleCollection) = n_particles(b)

## Weighted ##

"""
    WeightedParticleBelief{S}

Weighted particle belief consisting of particles of type `S` and their associated weights.

An alias table is used for efficient sampling.
"""
mutable struct WeightedParticleBelief{T} <: AbstractParticleBelief{T}
    particles::Vector{T}
    weights::Vector{Float64}
    weight_sum::Float64
    _probs::Union{Nothing, Dict{T,Float64}}
    _alias_table::Union{Nothing, AliasTable{UInt, Int}}
end

function WeightedParticleBelief(particles::AbstractVector{T},
                                weights::AbstractVector=ones(length(particles)),
                                weight_sum=sum(weights)) where {T}
    return WeightedParticleBelief{T}(particles, weights, weight_sum, nothing, nothing)
end

n_particles(b::WeightedParticleBelief) = length(b.particles)
particles(p::WeightedParticleBelief) = p.particles
weighted_particles(b::WeightedParticleBelief) = (b.particles[i]=>b.weights[i] for i in 1:length(b.particles))
weight_sum(b::WeightedParticleBelief) = b.weight_sum
weight(b::WeightedParticleBelief, i::Int) = b.weights[i]
particle(b::WeightedParticleBelief, i::Int) = b.particles[i]
weights(b::WeightedParticleBelief) = b.weights

function set_particle!(b::WeightedParticleBelief, i, s)
    b.particles[i] = s
end

function set_weight!(b::WeightedParticleBelief, i, w)
    weight_difference = w - b.weights[i]
    b.weight_sum += weight_difference
    b.weights[i] = w
    b._probs = nothing # invalidate _probs cache
    b._alias_table = nothing # invalidate alias table
end

function set_pair!(b::WeightedParticleBelief, i, sw)
    w = last(sw)
    s = first(sw)
    if !isnothing(b._probs)
        b._probs[particle(b, i)] -= weight(b, i)/weight_sum(b)
    end
    b.particles[i] = s
    weight_difference = w - b.weights[i]
    b.weight_sum += weight_difference
    b.weights[i] = w
    b._probs = nothing # invalidate _probs cache
    b._alias_table = nothing # invalidate alias table
    return sw
end

function push_pair!(b::WeightedParticleBelief, sw)
    push!(b.particles, first(sw))
    push!(b.weights, last(sw))
    b._probs = nothing # invalidate _probs cache
    b._alias_table = nothing # invalidate alias table
    return b
end

# Made the decision for now to have this always use alias sampling because this is more efficient when many samples are drawn, and usually many samples will be drawn.
# This should probably be upgraded to hook better into the Random API
# https://docs.julialang.org/en/v1/stdlib/Random/#An-optimized-sampler-with-pre-computed-data
# But many of the online solvers use rand(b) on every iteration. Perhaps they should be changed to use rand(b, number_of_samples) instead.
function Random.rand(rng::AbstractRNG, sampler::Random.SamplerTrivial{<:WeightedParticleBelief})
    b = sampler[]
    alias_single_sample(b, rng)
end

function alias_single_sample(b::WeightedParticleBelief, rng)
    if b._alias_table == nothing
        b._alias_table = AliasTable(b.weights)
    end
    at = b._alias_table::AliasTable{UInt, Int}

    return b.particles[rand(rng, at)]
end

function naive_single_sample(b::WeightedParticleBelief, rng)
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

function low_variance_sample(b::AbstractParticleBelief, n::Int, rng::AbstractRNG=Random.default_rng())
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
