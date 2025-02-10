# Basic Particle Filter

The [`BasicParticleFilter`](@ref) type is a flexible structure for building a particle filter. It simply contains functions that carry out each of the steps of a particle filter belief update.

The basic particle filtering step in ParticleFilters.jl is implemented in the [`update`](@ref) function, and consists of four steps:

1. Preprocessing - before the prediction step, it may be useful to preprocess the belief, for example resampling if there are not enough distinct particles
2. Prediction (or propagation) - each state particle is simulated forward one step in time
3. Reweighting - an explicit measurement (observation) model is used to calculate a new weight
4. Postprocessing - after the reweighting step, it may be useful to postprocess the belief, for example detecting particle degeneracy and sampling new particles that are consistent with the observation

In code, the update is written:
```julia
function update(up::BasicParticleFilter, b::AbstractParticleBelief, a, o)
    bb = up.preprocess(b, a, o, up.rng)
    particles = up.predict(bb, a, o, up.rng)
    weights = up.reweight(bb, a, particles, o)
    bp = WeightedParticleBelief(particles, weights)
    return up.postprocess(bp, a, o, b, bb, up.rng)
end
```

!!! note
    In the future, the steps in an `update` may change (for instance, the prediction and reweighting steps may be combined into a single function). However, we will maintain compatibility constructors so that code written for this 4-step process will continue to work.

A [`BasicParticleFilter`](@ref) is constructed by passing functions that implement each of the four steps. For example, a simple filter that adds Gaussian noise to each particle and reweights based on a Gaussian observation model is implemented in the following block. Note that there are no pre- or post-processing steps in this example.

```jldoctest basic; output=false, filter=r"BasicParticleFilter.*" => s"BasicParticleFilter"
using ParticleFilters, Distributions

preprocess(b, args...) = b
predict(b, a, o, rng) = particles(b) .+ a .+ randn(rng, n_particles(b))
reweight(b, a, particles, o) = weights(b) .* [pdf(Normal(p, 1.0), o) for p in particles]
postprocess(bp, args...) = bp

pf = BasicParticleFilter(preprocess, predict, reweight, postprocess)

# output

BasicParticleFilter()

```

This filter can be used for an update as follows:

```jldoctest basic; output=false, filter=r"WeightedParticleBelief.*" => s"WeightedParticleBelief"

b = ParticleCollection([1.0, 2.0, 3.0])
a = 1.0
o = 2.0

bp = update(pf, b, a, o)

# output

WeightedParticleBelief()

```

In order to give access to additional information such as static dynamics parameters, consider using a [`callable object`](https://docs.julialang.org/en/v1/manual/methods/#Function-like-objects). For additional examples, and to re-use elements from the `BootstrapFilter`, see the [`BootstrapFilter`](@ref) source code.

Some building blocks for constructing a `BasicParticleFilter` are provided in the `ParticleFilters` module. For example, the `BasicPredictor`, `BasicReweighter`, `POMDPPredictor`, and `POMDPReweighter` are not exported, but can be used to construct the `predict` and `reweight` functions for a `BasicParticleFilter`. The `check_particle_belief` function can be used as a postprocessing step, and `PostprocessChain` can be used to chain multiple postprocessing steps together. A function `(b, a, o, up.rng) -> ParticleCollection(low_variance_sample(b, 100, up.rng))` or `NormalizedESSConditionalResampler` can be used as a preprocessing step.

## Reference

```@docs
BasicParticleFilter
```
