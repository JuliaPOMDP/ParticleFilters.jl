
n_particles(b::ParticleCollection) = length(b.particles)
particles(p::ParticleCollection) = p.particles
weight_sum(::ParticleCollection) = 1.0
weight(b::ParticleCollection, i::Int) = 1.0/length(b.particles)
rand(rng::AbstractRNG, b::ParticleCollection) = b.particles[rand(rng, 1:length(b.particles))]
mean(b::ParticleCollection) = sum(b.particles)/length(b.particles)

n_particles(b::WeightedParticleBelief) = length(b.particles)
particles(p::WeightedParticleBelief) = p.particles
weight_sum(b::WeightedParticleBelief) = b.weight_sum
weight(b::WeightedParticleBelief, i::Int) = b.weights[i]
weights(b::WeightedParticleBelief) = b.weights

function rand(rng::AbstractRNG, b::WeightedParticleBelief)
    t = rand(rng) * weight_sum(b)
    i = 1
    cw = b.weights[1]
    while cw < t && i < length(b.weights)
        i += 1
        @inbounds cw += b.weights[i]
    end
    return particles(b)[i]
end
mean(b::WeightedParticleBelief) = dot(b.weights, b.particles)/weight_sum(b)

function pdf{S}(b::AbstractParticleBelief{S}, s::S)
    if isnull(b._probs)
        # search through the particle array (very slow)
        w = 0.0
        for i in 1:length(b.particles)
            if b.particles[i] == s
                w += weight(b,i)
            end
        end
        return w/weight_sum(b)
    else
        return get(get(b._probs), s, 0.0)
    end
end

function mode{T}(b::AbstractParticleBelief{T}) # don't know if this is efficient
    if isnull(b._probs)
        d = Dict{T, Float64}()
        best_weight = weight(b,1)
        most_likely = first(particles(b))
        ps = particles(b)
        for i in 2:n_particles(b)
            s = ps[i]
            if haskey(d, s)
                d[s] += weight(b, i)
            else
                d[s] = weight(b, i)
            end
            if d[s] > best_weight
                best_weight = d[s]
                most_likely = s
            end
        end
        return most_likely
    else
        probs = get(b._probs)
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
end

