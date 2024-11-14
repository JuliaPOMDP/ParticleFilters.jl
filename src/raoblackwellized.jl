abstract type RaoBlackwellizedParticleBelief end

struct RaoBlackwellizedParticleFilter <: Updater
    particle_filter::BasicParticleFilter
    analytical_filter::AbstractFilter # https://github.com/sisl/GaussianFilters.jl/blob/master/src/kf_classes.jl#L7
end

mutable struct RaoBlackwellizedParticleCollection{P, T<:AbstractVector{<:Number}, S<:Symmetric{<:Number}, SP, AP, R} <: RaoBlackwellizedParticleBelief
    particles::AbstractParticleBelief{P}
    analytical_beliefs::Vector{GaussianBelief{T, S}}
    sampled_part::SP
    analytical_part::AP
    reconstruct::R
end

function RaoBlackwellizedParticleCollection(
    particles::AbstractParticleBelief{P}, 
    analytical_beliefs::Vector{GaussianBelief{T, S}},
    sampled_part::SP, 
    analytical_part::AP, 
    reconstruct::R) where {P, T<:AbstractVector{<:Number}, S<:Symmetric{<:Number}, SP, AP, R}
    @assert n_particles(particles) == length(analytical_beliefs) "The number of particles must match the number of analytical beliefs."
    return RaoBlackwellizedParticleCollection{P, T, S, SP, AP, R}(
        particles,
        analytical_beliefs, 
        sampled_part, 
        analytical_part, 
        reconstruct)
end

ParticleFilters.n_particles(b::RaoBlackwellizedParticleCollection) = n_particles(b.particles)
ParticleFilters.particles(b::RaoBlackwellizedParticleCollection) = ParticleFilters.particles(b.particles)
ParticleFilters.particle(b::RaoBlackwellizedParticleCollection, i::Int) = ParticleFilters.particle(b.particles, i)

function Statistics.mean(b::RaoBlackwellizedParticleCollection{T}) where T
    particles_mean = mean(b.particles)
    normalized_weights = weights ./ sum(weights) 
    analytical_means = [belief.μ for belief in b.analytical_beliefs]
    weighted_analytical_mean = sum(normalized_weights .* analytical_means)
    return (particles_mean, weighted_analytical_mean)
end

function Statistics.cov(b::RaoBlackwellizedParticleCollection{T}) where T
    particles_cov = cov(b.particles)
    if b.particles isa ParticleCollection
        weights = fill(1.0 / n_particles(b.particles), n_particles(b.particles))
    else
        weights = b.particles.weights
    end
    normalized_weights = weights ./ sum(weights) 
    analytical_variances = [belief.Σ for belief in b.analytical_beliefs]
    weighted_analytical_variances = sum(normalized_weights .* analytical_variances)
    return (particles_cov, weighted_analytical_variances)
end

function Random.rand(rng::AbstractRNG, sampler::Random.SamplerTrivial{<:RaoBlackwellizedParticleCollection})
    b = sampler[]
    t = rand(rng) * weight_sum(b.particles)
    i = 1
    cw = b.particles.weights[1]
    while cw < t && i < length(b.particles.weights)
        i += 1
        @inbounds cw += b.particles.weights[i]
    end
	particle_states = b.particles.particles[i]
    linear_belief = b.analytical_beliefs[i]

    return RaoBlackwellizedParticleCollection(
        ParticleCollection([particle_states]),
        [linear_belief],
        b.sampled_part,
        b.analytical_part,
        b.reconstruct)
    return new_rbpc
end
