# Basic Particle Filter

The [`BasicParticleFilter`](@ref) type is a flexible structure for building a particle filter. It simply contains functions that carry out each of the steps of a particle filter belief update.

The basic particle filtering step in ParticleFilters.jl is implemented in the [`update`](@ref) function, and consists of four steps:

1. Preprocessing
2. Prediction (or propagation) - each state particle is simulated forward one step in time
3. Reweighting - an explicit measurement (observation) model is used to calculate a new weight
4. Postprocessing

!!! note
    In the future

## Docstrings

```@docs
BasicParticleFilter
```
