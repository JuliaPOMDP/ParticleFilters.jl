__precompile__()

module ParticleFilters

using POMDPs
using GenerativeModels
import POMDPs: pdf, mode, update, initialize_belief
import Base: rand, mean, eltype

export
    AbstractParticleBelief,
    ParticleCollection,
    WeightedParticleBelief,
    SimpleParticleFilter,
    ImportanceResampler,
    LowVarianceResampler,
    SIRParticleFilter

export
    resample,
    n_particles,
    particles,
    weight_sum,
    weight,
    weights


abstract AbstractParticleBelief{T}
Base.eltype{T}(::Type{AbstractParticleBelief{T}}) = T

"""
Unweighted particle belief
"""
immutable ParticleCollection{T} <: AbstractParticleBelief{T}
    particles::Vector{T}
    _probs::Nullable{Dict{T,Float64}}
end
ParticleCollection{T}(p::AbstractVector{T}) = ParticleCollection{T}(p, nothing)

n_particles(b::ParticleCollection) = length(b.particles)
particles(p::ParticleCollection) = p.particles
weight_sum(::ParticleCollection) = 1.0
weight(b::ParticleCollection, i::Int) = 1.0/length(b.particles)
rand(rng::AbstractRNG, b::ParticleCollection) = b.particles[rand(rng, 1:length(b.particles))]
mean(b::ParticleCollection) = sum(b.particles)/length(b.particles)

immutable WeightedParticleBelief{T} <: AbstractParticleBelief{T}
    particles::Vector{T}
    weights::Vector{Float64}
    weight_sum::Float64
    _probs::Nullable{Dict{T,Float64}}
end

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
    return
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

type SimpleParticleFilter{S,R} <: Updater{ParticleCollection{S}}
    pomdp::POMDP{S}
    resample::R
    rng::AbstractRNG
    _particle_memory::Vector{S}
    _weight_memory::Vector{Float64}
end
SimpleParticleFilter{S,R}(pomdp::POMDP{S}, resample::R, rng::AbstractRNG) = SimpleParticleFilter(pomdp, resample, rng, S[], Float64[])
SimpleParticleFilter{S,R}(pomdp::POMDP{S}, resample::R; rng::AbstractRNG=Base.GLOBAL_RNG) = SimpleParticleFilter(pomdp, resample, rng)

initialize_belief{S}(up::SimpleParticleFilter{S}, d::Any) = resample(up.resample, d, up.rng)

function update{S}(up::SimpleParticleFilter{S}, b::ParticleCollection, a, o)
    ps = particles(b)
    pm = up._particle_memory
    wm = up._weight_memory
    resize!(pm, 0)
    resize!(wm, 0)
    sizehint!(pm, n_particles(b))
    sizehint!(wm, n_particles(b))
    all_terminal = true
    for i in 1:n_particles(b)
        s = ps[i]
        if !isterminal(up.pomdp, s)
            all_terminal = false
            sp = generate_s(up.pomdp, s, a, up.rng)
            push!(pm, sp)
            od = observation(up.pomdp, s, a, sp)
            push!(wm, pdf(od, o))
        end
    end
    if all_terminal
        error("Particle filter update error: all states in the particle collection were terminal.")
    end
    return resample(up.resample, WeightedParticleBelief{S}(pm, wm, sum(wm), nothing), up.rng)
end

resample(f::Function, d::Any, rng::AbstractRNG) = f(d, rng)

immutable ImportanceResampler
    n::Int
end

function resample{S}(r::ImportanceResampler, b::WeightedParticleBelief{S}, rng::AbstractRNG)
    #XXX this may break if StatsBase changes
    ps = Array(S, r.n)
    alias_sample!(rng, particles(b), weights(b), weight_sum(b), ps)
    return ParticleCollection(ps)
end

typealias SIRParticleFilter{T} SimpleParticleFilter{T, ImportanceResampler}

function SIRParticleFilter{S}(pomdp::POMDP{S}, n::Int; rng::AbstractRNG=Base.GLOBAL_RNG)
    return SimpleParticleFilter(pomdp, ImportanceResampler(n), rng)
end

# low variance sampling algorithm on page 110 of Probabilistic Robotics by Thrun Burgard and Fox
immutable LowVarianceResampler
    n::Int
end

function resample{S}(re::LowVarianceResampler, b::AbstractParticleBelief{S}, rng::AbstractRNG)
    ps = Array(S, re.n)
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

function resample(r::Union{ImportanceResampler,LowVarianceResampler}, b, rng::AbstractRNG)
    ps = Array(eltype(b), r.n)
    for i in 1:r.n
        ps[i] = rand(rng, b)
    end
    return ParticleCollection(ps)
end

include("alias_sample.jl")

end # module
