# Home

ParticleFilters.jl provides a basic [particle filter](https://en.wikipedia.org/wiki/Particle_filter) representation along with some useful tools for constructing more complex particle filters.

In particular it provides both weighted and unweighted [particle belief types](@ref Beliefs) that implement the [POMDPs.jl distribution interface](http://juliapomdp.github.io/POMDPs.jl/latest/interfaces.html#Distributions-1) including sampling and automatic caching of probability mass calculations.

Additionally, an important requirement for a particle filter is efficient resampling. This package provides O(n) [resamplers](@ref).

Dynamics and measurement models for the filters can be specified as a [`ParticleFilterModel`](@ref) or [`POMDP`](https://github.com/JuliaPOMDP/POMDPs.jl).

The simplest sampling-importance-resampling Particle filter can be constructed with [SIRParticleFilter](@ref). [BasicParticleFilter](@ref) provides a more flexible structure.

There are tutorials for three ways to use the particle filters:
1. As an [estimator for feedback control](),
2. to [filter time-series measurements](), and
3. as an [updater for POMDPs.jl]().

For documentation on all aspects of the package, see the contents below.

## Contents

```@contents
```
