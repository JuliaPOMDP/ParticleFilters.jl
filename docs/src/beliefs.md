# Beliefs

## Types

ParticleFilters.jl provides two [types of particle beliefs](#Types-1). `ParticleCollection` is little more than a vector of unweighted particles. `WeightedParticleBelief` allows for different weights for each of the particles.

Both are subtypes of `AbstractParticleBelief` and implement the same [particle belief interface](#Interface-1). For probability mass calculations (the [`pdf`](@ref) function), a dictionary containing the normalized sum of weights for all identical particles is created on the first call and cached for efficient future querying.

!!! warning
    You should not access the fields of `ParticleCollection` or `WeightedParticleBelief` directly. Use the provided [interface](#Interface-1) instead to ensure that internal data structures are maintained correctly.

```@docs
ParticleCollection
WeightedParticleBelief
```

## Interface

### Standard POMDPs.jl Distribution Interface

The following functions from the [POMDPs.jl distributions interface](http://juliapomdp.github.io/POMDPs.jl/latest/interfaces.html#Distributions-1) (a subset of the Distributions.jl interface) provide basic ways of interacting with particle beliefs as distributions (click on each for documentation):

- [`rand`](@ref)
- [`pdf`](@ref)
- [`support`](@ref)
- [`mode`](@ref)
- [`mean`](@ref)

### Particle Interface

These functions provide *read only* access to the particles, weights, and other aspects of the beliefs (click on each for docstrings):

- [`n_particles`](@ref)
- [`particles`](@ref)
- [`weights`](@ref)
- [`weighted_particles`](@ref)
- [`weight_sum`](@ref)
- [`weight`](@ref)
- [`particle`](@ref)
- [`ParticleFilters.probdict`](@ref)
- [`effective_sample_size`](@ref)

To change the particles or weights in a belief, the following functions are provided:

- [`set_particle!`](@ref)
- [`set_weight!`](@ref)
- [`set_pair!`](@ref)
- [`push_pair!`](@ref)

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
effective_sample_size
set_particle!
set_weight!
set_pair!
push_pair!
```


