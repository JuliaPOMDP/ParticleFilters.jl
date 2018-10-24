# Basic Particle Filter

The basic particle filtering step in ParticleFilters.jl consists of three steps:

1. Prediction (or propagation) - each state particle is simulated forward one step in time
2. Reweighting - an explicit measurement (observation) model is used to calculate a new weight
3. Resampling - a new collection of state particles is generated with particle frequencies proportional to the new weights

This is an example of [sequential importance resampling](https://en.wikipedia.org/wiki/Particle_filter#Sequential_Importance_Resampling_(SIR)), and the [`SIRParticleFilter`](@ref) constructor can be used to construct such a filter with a `model` that controls the prediction and reweighting steps, and a number of particles to create in the resampling phase.

A more flexible structure for building a particle filter is the [`BasicParticleFilter`](@ref). It contains three models, one for each step:

1. The `predict_model` controls prediction through [`predict!`](@ref)
2. The `reweight_model` controls reweighting through [`reweight!`](@ref)
3. The `resampler` controls resampling through [`resample`](@ref)

ParticleFilters.jl contains implementations of these components that can be mixed and matched. In many cases the prediction and reweighting steps use the same model, for example a [`ParticleFilterModel`](@ref) or a [`POMDP`](https://github.com/JuliaPOMDP/POMDPs.jl).

To carry out the steps individually without the need for pre-allocating memory or doing a full `update` step, the [`predict`](@ref), [`reweight`](@ref), and [`resample`](@ref) functions are provided.

## Docstrings

```@docs
SIRParticleFilter
BasicParticleFilter
predict!
reweight!
resample
predict
reweight
```
