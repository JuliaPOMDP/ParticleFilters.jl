# Home

ParticleFilters.jl provides a basic [particle filter](https://en.wikipedia.org/wiki/Particle_filter), along with some useful tools for constructing more complex particle filters.
In particular it provides both weighted and unweighted [particle belief types](@ref Beliefs) that implement the [POMDPs.jl distribution interface](http://juliapomdp.github.io/POMDPs.jl/latest/interfaces.html#Distributions-1) including sampling and automatic caching of probability mass calculations.
Additionally, an important requirement for a particle filter is efficient resampling. This package provides O(n) [sampling](@ref Sampling).

Dynamics and measurement models for the filters can be specified with a few functions or a [`POMDP`](https://github.com/JuliaPOMDP/POMDPs.jl). The simplest Bootstrap Particle filter can be constructed with [`BootstrapFilter`](@ref). [`BasicParticleFilter`](@ref) provides a more flexible structure.

There are [tutorials](/notebooks) for three ways to use the particle filters:
1. As an [estimator for feedback control](notebooks/Using-a-Particle-Filter-for-Feedback-Control.html),
2. to [filter time-series measurements](notebooks/Filtering-a-Trajectory-or-Data-Series.html), and
3. as an [updater for POMDPs.jl](notebooks/Using-a-Particle-Filter-with-POMDPs-jl.html).

For documentation on all aspects of the package, see the contents below.

## Contents

```@contents
```
