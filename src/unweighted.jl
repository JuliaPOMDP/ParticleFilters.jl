"""
UnweightedParticleFilter

A particle filter that does not use any reweighting, but only keeps particles if the observation matches the true observation exactly. This does not require obs_weight, but it will not work well in real-world situations.
"""
struct UnweightedParticleFilter{M, RNG<:AbstractRNG} <: Updater
    model::M
    n::Int
    rng::RNG
end

function UnweightedParticleFilter(model, n::Integer; rng=Base.GLOBAL_RNG)
    return UnweightedParticleFilter(model, n, rng)
end

function update(up::UnweightedParticleFilter, b::ParticleCollection, a, o)
    new = sampletype(b)[]
    i = 1
    while i <= up.n
        s = particle(b, mod1(i, n_particles(b)))
        sp, o_gen = generate_so(up.model, s, a, up.rng)
        if o_gen == o
            push!(new, sp)
        end
        i += 1
    end
    if isempty(new)
        warn("""
             Particle Depletion!

             The UnweightedParticleFilter generated no particles consistent with observation $o. Consider upgrading to a SIRParticleFilter or a BasicParticleFilter or creating your own domain-specific updater.
             """
            )
    end
    return ParticleCollection(new)
end

function update(up::UnweightedParticleFilter, b, a, o)
    return update(up, initialize_belief(up, b), a, o)
end

function initialize_belief(up::UnweightedParticleFilter, b)
    return ParticleCollection(collect(rand(up.rng, b) for i in 1:up.n))
end
