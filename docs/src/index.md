# Home

ParticleFilters.jl provides a basic [particle filter](https://en.wikipedia.org/wiki/Particle_filter) representation along with some useful tools for constructing more complex particle filters.

In particular it provides both weighted and unweighted [particle belief types](@ref Beliefs) that implement the [POMDPs.jl distribution interface](http://juliapomdp.github.io/POMDPs.jl/latest/interfaces.html#Distributions-1) including sampling and automatic caching of probability mass calculations.

Additionally, an important requirement for a particle filter is efficient resampling. This package provides O(n) [resamplers](@ref Resamplers).

Dynamics and measurement models for the filters can be specified as a [`ParticleFilterModel`](@ref) or a [`POMDP`](https://github.com/JuliaPOMDP/POMDPs.jl) or a custom user-defined type.

The simplest Bootstrap Particle filter can be constructed with [`BootstrapFilter`](@ref). [`BasicParticleFilter`](@ref) provides a more flexible structure.

Basic setup of a model is as follows:
```julia
using ParticleFilters, Distributions

dynamics(x, u, rng) = x + u + randn(rng)
y_likelihood(x_previous, u, x, y) = pdf(Normal(), y - x)
model = ParticleFilterModel{Float64}(dynamics, y_likelihood)
pf = BootstrapFilter(model, 10)
```
Then the [`update`](@ref) function can be used to perform a particle filter update.
```julia
b = ParticleCollection([1.0, 2.0, 3.0, 4.0])
u = 1.0
y = 3.0

b_new = update(pf, b, u, y)
```

There are tutorials for three ways to use the particle filters:
1. As an [estimator for feedback control](https://github.com/JuliaPOMDP/ParticleFilters.jl/notebooks/Using-a-Particle-Filter-for-Feedback-Control.ipynb),
2. to [filter time-series measurements](https://github.com/JuliaPOMDP/ParticleFilters.jl/notebooks/Filtering-a-Trajectory-or-Data-Series.ipynb), and
3. as an [updater for POMDPs.jl](https://github.com/JuliaPOMDP/ParticleFilters.jl/blob/master/notebooks/Using-a-Particle-Filter-with-POMDPs-jl.ipynb).

For documentation on all aspects of the package, see the contents below.

## Contents

```@contents
```
