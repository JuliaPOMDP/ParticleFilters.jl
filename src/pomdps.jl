# this file contains functions for glue between this package and POMDPs.jl

struct POMDPPredicter{M<:POMDP} <: Function
    m::M
end

function (pre::POMDPPredicter)(b, a, o, rng)
    all_terminal = true
    ps = Array{gentype(b)}(undef, n_particles(b))
    for i in 1:n_particles(b)
        s = particle(b, i)
        if !isterminal(pre.m, s)
            all_terminal = false
            sp = @gen(:sp)(pre.m, s, a, rng)
            ps[i] = sp
        else
            ps[i] = s
        end
    end
    if all_terminal
        error("Particle filter update error: all states in the particle collection were terminal.")
    end
    return ps
end

struct POMDPReweighter{M<:POMDP} <: Function
    m::M
end

function (rw::POMDPReweighter)(b, a, particles, o)
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

function POMDPs.initialize_belief(up::BasicParticleFilter, d)
    return up.initialize(d, up.rng)
end
