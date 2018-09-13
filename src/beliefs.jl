n_particles(b::ParticleCollection) = length(b.particles)
particles(p::ParticleCollection) = p.particles
weighted_particles(p::ParticleCollection) = (s=>1.0/length(p.particles) for s in p.particles)
weight_sum(::ParticleCollection) = 1.0
weight(b::ParticleCollection, i::Int) = 1.0/length(b.particles)
particle(b::ParticleCollection, i::Int) = b.particles[i]
rand(rng::AbstractRNG, b::ParticleCollection) = b.particles[rand(rng, 1:length(b.particles))]
Statistics.mean(b::ParticleCollection) = sum(b.particles)/length(b.particles)
support(b::ParticleCollection) = unique(particles(b))

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

function get_probs(b::AbstractParticleBelief{S}) where {S}
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

pdf(b::AbstractParticleBelief{S}, s::S) where {S} = get(get_probs(b), s, 0.0)

function mode(b::AbstractParticleBelief{T}) where {T} # don't know if this is efficient
    probs = get_probs(b)
    best_weight = 0.0
    most_likely = first(keys(probs))
    for (s,w) in probs
        if w > best_weight
            best_weight = w
            most_likely = s
        end
    end
    return most_likely
end

support(b::AbstractParticleBelief) = keys(get_probs(b))
