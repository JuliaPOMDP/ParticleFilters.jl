# Bootstrap Filter

The [`BootstrapFilter`](@ref) is the simplest filter provided by the library and should be the starting point for most tasks.

## Quick Start

With a POMDPs.jl model, setup looks like this:
```jldoctest intro; output=false, filter=r"BasicParticleFilter.*" => s"BasicParticleFilter"
using ParticleFilters, POMDPModels

pomdp = TigerPOMDP()
pf = BootstrapFilter(pomdp, 10)

# output

BasicParticleFilter()
```

Without POMDPs.jl, setup looks like this:
```jldoctest intro; output=false, filter=r"BasicParticleFilter.*" => s"BasicParticleFilter"
using ParticleFilters, Distributions

dynamics(x, u, rng) = x + u + randn(rng)
y_likelihood(x_previous, u, x, y) = pdf(Normal(), y - x)
pf = BootstrapFilter(dynamics, y_likelihood, 10)

# output

BasicParticleFilter()

```

Once the filter has been created the [`update`](@ref) function can be used to perform a particle filter update.
```jldoctest intro; output=false, filter=r"WeightedParticleBelief.*" => s"WeightedParticleBelief"
b = ParticleCollection([1.0, 2.0, 3.0, 4.0])
u = 1.0
y = 3.0

b_new = update(pf, b, u, y)

# output

WeightedParticleBelief()
```

## More on the Bootstrap Filter

The [`BootstrapFilter`](@ref) is designed to be a sensible default choice for starting with particle filtering. The basic bootstrap filter approach was first described in "Novel approach to nonlinear / non-Gaussian Bayesian state estimation" by Gordon, Salmond, and Smith.
The version in this package first checks whether the normalized [effective sample size](@ref effective_sample_size) of the particle belief is above a threshold (the `resample_threshold` argument). If it is below the threshold, the belief is resampled using [`low_variance_sample`](@ref). The particles are then propagated through the dynamics model and weighted by the likelihood of the observation. 

The `BootstrapFilter` offers a modest level of customization. The most common need for customization is recovering from particle depletion. For this case, use the `postprocess` keyword argument to specify a function that can be used to check for depletion and recover. See the [Handling Particle Depletion](@ref) section for more information about this task. If more customization is needed, users should use the [`BasicParticleFilter`](@ref).

```@docs
BootstrapFilter
```
