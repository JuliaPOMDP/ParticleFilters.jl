# Models

The [`BasicParticleFilter`](@ref) requires two pieces of information about the system that is being filtered:

1. A generative dynamics model, which determines how the state will change (possibly stochastically) over time, and
2. An explicit model of the observation distribution.

The [`ParticleFilterModel`](@ref) provides a standard structure for these two elements. The first parameter of the type, `S`, specifies the state type. The constructor arguments are two functions. The first, `f`, is the dynamics function, which produces the next state given the current state, control, and a random number generator as arguments. The second function, `g` is describes the weight that should be given to the particle given the original state, control, final state, and observation as arguments. See the docstring below and the [feedback control]() and [filtering]() tutorials for more info.

`ParticleFilters.jl` requires the `rng` argument in the system dynamics functions for the sake of reproducibility independent of the simulation or control system.

The dynamics and reweighting models may also be specified separately using [`PredictModel`](@ref) and [`ReweightModel`](@ref).

Note that a [`POMDP`](https://github.com/JuliaPOMDP/POMDPs.jl) with [`generate_s`](http://juliapomdp.github.io/POMDPs.jl/latest/api.html#POMDPs.generate_s) and [`obs_weight`](https://juliapomdp.github.io/POMDPModelTools.jl/latest/interface_extensions.html#POMDPModelTools.obs_weight) implemented may also serve as a model.

## Docstrings

```@docs
ParticleFilterModel
PredictModel
ReweightModel
```
