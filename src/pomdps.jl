# this file contains functions for glue between this package and POMDPs.jl

function reweight!(wm, m::POMDP, b, a, pm, o)
    for i in 1:n_particles(b)
        s = particle(b, i)
        if isterminal(m, s)
            wm[i] = 0.0
        else
            sp = pm[i]
            wm[i] = obs_weight(m, s, a, sp, o)
        end
    end
end

function predict!(pm, m::POMDP, b, a, rng)
    all_terminal = true
    for i in 1:n_particles(b)
        s = particle(b, i)
        if isterminal(m, s)
            pm[i] = undef
        else
            all_terminal = false
            sp = generate_s(m, s, a, rng)
            pm[i] = sp
        end
    end
    if all_terminal
        error("Particle filter update error: all states in the particle collection were terminal.")
    end
end

particle_memory(pmodel::POMDP) = statetype(pmodel)[]

# all of the lines with resample should be changed to rand(rng, d, 3) when that becomes part of the POMDPs.jl standard

function initialize_belief(up::BasicParticleFilter, b::AbstractParticleBelief)
    return resample(ImportanceResampler(up.n_init), b, up.rng) # resample is needed to control number of particles
end

function initialize_belief(up::BasicParticleFilter, b::AbstractVector)
    pc = ParticleCollection(b)
    return resample(ImportanceResampler(up.n_init), pc, up.rng)
end

function initialize_belief(up::BasicParticleFilter, d::D) where D
    # using weighted iterator here is more likely to be order n than just calling rand() repeatedly
    # but, this implementation may change in the future
    if @implemented(support(::D)) && @implemented(pdf(::D, ::typeof(first(support(d)))))
    # if @implemented(weighted_iterator(::D))
        S = typeof(first(support(d)))
        particles = S[]
        weights = Float64[]
        for (s, w) in weighted_iterator(d)
            push!(particles, s)
            push!(weights, w)
        end
        return resample(ImportanceResampler(up.n_init), WeightedParticleBelief(particles, weights), up.rng)
    else
        return ParticleCollection(collect(rand(up.rng, d) for i in 1:up.n_init))
    end
end
