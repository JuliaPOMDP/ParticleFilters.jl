# Handling Particle Depletion

Many of the most common problems with particle filters are related to particle depletion, that is, a lack of particles corresponding to the true state. In many cases, it is not difficult to overcome these problems, but domain-specific heuristics are often more effective than generic approaches.

The recommended first remedy for particle depletion is to write a custom domain-specific [resampler](@ref Resamplers) that injects new appropriate particles in the case of particle depletion. The particle depletion can be detected by observing low likelihood weights and handling it within the [`resample`](@ref) function.

The example below contains a more robust resampler for [POMDP](https://github.com/JuliaPOMDP/POMDPs.jl) models. When it detects a complete particle depletion with [`weight_sum`](@ref)`(bp) == 0.0`, it replaces the particles by sampling from the initial state distribution.

```julia
using POMDPs
using ParticleFilters

struct POMDPResampler
    n::Int
end

function ParticleFilters.resample(r::POMDPResampler,
                                  bp::WeightedParticleBelief,
                                  pm::POMDP,
                                  rm::POMDP,
                                  b,
                                  a,
                                  o,
                                  rng)

    if weight_sum(bp) == 0.0
        # no appropriate particles - resample from the initial distribution
        new_ps = [initialstate(pm, rng) for i in 1:r.n]
        return ParticleCollection(new_ps)
    else
        # normal resample
        return resample(LowVarianceResampler(r.n), bp, rng)
    end
end
```

If it is not possible to handle particle depletions only within [`resample`](@ref), then it may be possible to handle with a custom prediction or reweighting model, or it may be best to write a new filter using the building blocks in this package. A good way to get started on this is to look at the implementation of the [`update`](@ref) function of the [`BasicParticleFilter`](@ref)
