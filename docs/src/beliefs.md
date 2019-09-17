# Beliefs

## Types

ParticleFilters.jl provides two [types of particle beliefs](#Types-1). `ParticleCollection` is little more than a vector of unweighted particles. `WeightedParticleBelief` allows for different weights for each of the particles.

Both are subtypes of `AbstractParticleBelief` and implement the same [particle belief interface](#Interface-1). For probability mass calculations (the [`pdf`](@ref) function), a dictionary containing the normalized sum of weights for all identical particles is created on the first call and cached for efficient future querying.

```@docs
ParticleCollection
WeightedParticleBelief
```

## Interface

### Standard POMDPs.jl Distribution Interface

The following functions from the [POMDPs.jl distributions interface](http://juliapomdp.github.io/POMDPs.jl/latest/interfaces.html#Distributions-1) provide basic ways of interacting with particle beliefs as distributions (click on each for documentation):

- [`rand`](@ref)
- [`pdf`](@ref)
- [`support`](@ref)
- [`mode`](@ref)
- [`mean`](@ref)

### Particle Interface

These functions provide access to the particles and weights in the beliefs (click on each for docstrings):

- [`n_particles`](@ref)
- [`particles`](@ref)
- [`weights`](@ref)
- [`weighted_particles`](@ref)
- [`weight_sum`](@ref)
- [`weight`](@ref)
- [`particle`](@ref)
- [`ParticleFilters.probdict`](@ref)

### Interface Docstrings

```@docs
POMDPs.rand
POMDPs.pdf
POMDPs.support
POMDPs.mode
POMDPs.mean
n_particles
particles
weights
weighted_particles
weight_sum
weight
particle
ParticleFilters.probdict
```


