function resample{S}(r::ImportanceResampler, b::WeightedParticleBelief{S}, rng::AbstractRNG)
    ps = Array{S}(r.n)
    if weight_sum(b) <= 0
        warn("Invalid weights in particle filter: weight_sum = $(weight_sum(b))")
    end
    #XXX this may break if StatsBase changes
    StatsBase.alias_sample!(rng, particles(b), Weights(weights(b), weight_sum(b)), ps)
    return ParticleCollection(ps)
end

function resample{S}(re::LowVarianceResampler, b::AbstractParticleBelief{S}, rng::AbstractRNG)
    ps = Array{S}(re.n)
    r = rand(rng)*weight_sum(b)/re.n
    c = weight(b,1)
    i = 1
    U = r
    for m in 1:re.n
        while U > c
            i += 1
            c += weight(b, i)
        end
        U += weight_sum(b)/re.n
        ps[m] = particles(b)[i]
    end
    return ParticleCollection(ps)
end

function resample{S}(re::LowVarianceResampler, b::ParticleCollection{S}, rng::AbstractRNG)
    r = rand(rng)*n_particles(b)/re.n
    chunk = n_particles(b)/re.n
    inds = ceil.(Int, chunk*(0:re.n-1)+r)
    ps = particles(b)[inds]
    return ParticleCollection(ps)
end

resample(r::Union{ImportanceResampler,LowVarianceResampler}, b, rng::AbstractRNG) = resample(r, b, sampletype(b), rng)

function resample(r::Union{ImportanceResampler,LowVarianceResampler}, b, sampletype::Type, rng::AbstractRNG)
    ps = Array{sampletype}(r.n)
    for i in 1:r.n
        ps[i] = rand(rng, b)
    end
    return ParticleCollection(ps)
end
