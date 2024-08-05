# this file contains functions for glue between this package and POMDPs.jl

struct POMDPPredict{M<:POMDP} <: Function
    m::M
end

function (pre::POMDPPredict)(b, a, o, rng)
    all_terminal = true
    ps = Array{gentype(b)}(undef, n_particles(b))
    for i in 1:n_particles(b)
        s = particle(b, i)
        if !isterminal(pre.m, s)
            all_terminal = false
            sp = @gen(:sp)(pre.m, s, a, rng)
            ps[i] = sp
        end
    end
    if all_terminal
        error("Particle filter update error: all states in the particle collection were terminal.")
    end
    return ps
end

struct POMDPReweight{M<:POMDP} <: Function
    m::M
end

function (rw::POMDPReweight)(bb, a, particles, o)
    ws = Array{Float64}(undef, length(particles))
    for i in 1:n_particles(b)
        s = particle(b, i)
        if isterminal(rw.m, s)
            ws[i] = 0.0
        else
            sp = particles[i]
            ws[i] = obs_weight(rw.m, s, a, sp, o)
        end
    end
    return ws
end

# particle_memory(pmodel::POMDP) = statetype(pmodel)[]

# all of the lines with resample should be changed to rand(rng, d, 3) when that becomes part of the POMDPs.jl standard

function initialize_belief(up::BasicParticleFilter, b::AbstractParticleBelief)
    return up.initialize(b, up.rng) # resample is needed to control number of particles
end

function initialize_belief(up::BasicParticleFilter, b::ParticleCollection)
    if n_particles(b) == up.n_init
        return b
    else
        return up.initialize(b, up.rng) # resample is needed to control number of particles
    end
end

function initialize_belief(up::BasicParticleFilter, b::AbstractVector)
    pc = ParticleCollection(b)
    return resample(ImportanceResampler(up.n_init), pc, up.rng)
end

function initialize_belief(up::BasicParticleFilter, d::D) where D
    # using weighted iterator here is more likely to be order n than just calling rand() repeatedly
    # but, this implementation is problematic and may change in the future
    try
        if @implemented(support(::D)) &&
            @implemented(iterate(::typeof(support(d)))) &&
            @implemented(pdf(::D, ::typeof(first(support(d)))))
                S = typeof(first(support(d)))
                particles = S[]
                weights = Float64[]
                for (s, w) in weighted_iterator(d)
                    push!(particles, s)
                    push!(weights, w)
                end
                return resample(ImportanceResampler(up.n_init), WeightedParticleBelief(particles, weights), up.rng)
        end
    catch ex
        if ex isa MethodError
            @warn("""
                Suppressing MethodError in initialize_belief in ParticleFilters.jl. Please file an issue here:

                https://github.com/JuliaPOMDP/ParticleFilters.jl/issues/new

                The error was

                $(sprint(showerror, ex))
                  """, maxlog=1)
        else
            rethrow(ex)
        end
    end

    return ParticleCollection(collect(rand(up.rng, d) for i in 1:up.n_init))
end
