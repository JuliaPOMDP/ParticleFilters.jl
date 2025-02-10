PostprocessChain(functions...) = reduce((f, g) -> (bp, a, o, b, bb, rng) -> g(f(bp, a, o, b, bb, rng), a, o, b, bb, rng), functions)

function check_particle_belief(b::AbstractParticleBelief)
    if length(particles(b)) != length(weights(b))
        @warn "Number of particles and weights do not match" length(particles(b)) length(weights(b))
    end
    if weight_sum(b) <= 0.0
        @warn """Sum of particle filter weights is not greater than zero. This
        could be due to particle depletion. See the documentation of the
        ParticleFilters package for instructions on handling particle depletion.""" weight_sum(b)
    end
    if !(sum(weights(b)) ≈ weight_sum(b))
        @warn "Sum of particle filter weights does not match weight_sum." sum(weights(b)) weight_sum(b)
    end
end

# this handles the extra arguments needed for a postprocessing function
function check_particle_belief(bp, args...)
    check_particle_belief(bp)
    return bp
end

#=
struct ReplaceWithInitial{M <: POMDP} <: Function
    threshold::Float64
    m::M
end

# It is not clear if the entire distribution should be replaced or something else.
function (r::ReplaceWithInitial)(bp, a, o, b, bb, rng)
    ps = particles(bp)
    ws = weights(bp)
    n = n_particles(bp)
    if weight_sum(bp) == 0.0
        return ParticleCollection([initial_state(r.m) for i in 1:n])
    end
    return bp
end
=#
