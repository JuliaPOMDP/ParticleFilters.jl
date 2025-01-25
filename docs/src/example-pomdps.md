# Example: Use with POMDPs.jl

The particle filters in `ParticleFilters.jl` can be used out of the box as [updaters](http://juliapomdp.github.io/POMDPs.jl/latest/concepts.html#beliefs_and_updaters-1) for [POMDPs.jl](https://github.com/JuliaPOMDP/POMDPs.jl). This tutorial will briefly demonstrate usage with the [LightDark problem from POMDPModels.jl](https://github.com/JuliaPOMDP/POMDPModels.jl/blob/master/src/LightDark.jl).

```@example pomdps
using ParticleFilters
using POMDPs
using POMDPModels
using POMDPTools
using Random
using Plots
```

## Running a Simulation

The following code creates the pomdp model and the associated particle filter and runs a simulation producing a history.

```@example pomdps
rng = MersenneTwister(1)
pomdp = LightDark1D();
N = 5000;
up = BootstrapFilter(pomdp, N, rng=rng);
policy = FunctionPolicy(b->1);
b0 = POMDPModels.LDNormalStateDist(-15.0, 5.0);
hr = HistoryRecorder(rng = rng, max_steps=40);

history = simulate(hr, pomdp, policy, up, b0);
nothing # hide
```

## Visualization

We can then plot the particle distribution at each step using Plots.jl.

Note that as the belief passes through the light region (centered at y=5)

```@example pomdps
@gif for b in belief_hist(history)
    local ys = [s.y for s in particles(b)]
    local nbins = max(1, round(Int, (maximum(ys)-minimum(ys))*2))
    histogram(
        ys,
        xlim = (-20,20),
        ylim = (0,1000),
        nbins = nbins,
        label = "",
        title = "Particle Histogram"
    )                    
end fps=5
```
