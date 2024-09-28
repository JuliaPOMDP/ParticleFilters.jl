PostprocessChain(functions...) = reduce((f, g) -> (bp, b, a, o, rng) -> g(f(bp, b, a, o, rng), b, a, o, rng), functions)

function check_particle_belief(b::AbstractParticleBelief)
    if length(particles(b)) != length(weights(b))
        @warn "Number of particles and weights do not match" length(particles(b)) length(weights(b))
    end
    if weight_sum(b) <= 0.0
        @warn "Sum of particle filter weights is not greater than zero." weight_sum(b)
    end
    if sum(weights(b)) !≈ weight_sum(b)
        @warn "Sum of particle filter weights does not match weight_sum." sum(weights(b)) weight_sum(b)
    end
end

check_particle_belief(bp, args...) = check_belief(bp) && return bp

struct ReplaceWithInitial{M <: POMDP} <: Function
    threshold::Float64
    m::M
end

# TODO
function (r::ReplaceWithInitial)(bp, b, a, o, rng)
    ps = particles(bp)
    ws = weights(bp)
    n = n_particles(bp)
    if weight_sum(bp) == 0.0
        return ParticleCollection([initial_state(r.m) for i in 1:n])
    end
    return bp
end
