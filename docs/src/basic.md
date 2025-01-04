# Basic Particle Filter

The 

## Update Steps

The basic particle filtering step in ParticleFilters.jl is implemented in the [`update`](@ref) function, and consists of three steps:

1. Prediction (or propagation) - each state particle is simulated forward one step in time
2. Reweighting - an explicit measurement (observation) model is used to calculate a new weight
3. Resampling - a new collection of state particles is generated with particle frequencies proportional to the new weights

This is an example of [sequential importance resampling](https://en.wikipedia.org/wiki/Particle_filter#Sequential_Importance_Resampling_(SIR)) using the state transition distribution as the proposal distribution, and the [`BootstrapFilter`](@ref) constructor can be used to construct such a filter with a `model` that controls the prediction and reweighting steps, and a number of particles to create in the resampling phase.

A more flexible structure for building a particle filter is the [`BasicParticleFilter`](@ref). It contains three models, one for each step:

1. The `predict_model` controls prediction through [`predict!`](@ref)
2. The `reweight_model` controls reweighting through [`reweight!`](@ref)
3. The `resampler` controls resampling through [`resample`](@ref)


## Docstrings

```@docs
BootstrapFilter
BasicParticleFilter
update
```
