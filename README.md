# ParticleFilters

[![Build Status](https://travis-ci.org/JuliaPOMDP/ParticleFilters.jl.svg?branch=master)](https://travis-ci.org/JuliaPOMDP/ParticleFilters.jl?branch=master)
[![codecov.io](http://codecov.io/github/JuliaPOMDP/ParticleFilters.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaPOMDP/ParticleFilters.jl?branch=master)
<!--[![Coverage Status](https://coveralls.io/repos/JuliaPOMDP/ParticleFilters.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JuliaPOMDP/ParticleFilters.jl?branch=master)-->

![particles.gif](/img/particles.gif)

This package rovides some simple generic particle filters, and may serve as a template for making custom particle filters and other updaters for POMDPs.jl.

# Installation

In Julia:

```julia
Pkg.add("ParticleFilters")
```

# Usage

ParticleFilters.jl can be be used with or without the [POMDPs.jl](https://github.com/JuliaPOMDP/POMDPs.jl) package, so usage instructions are divided into two sections. First [usage without POMDPs.jl](#usage-without-pomdpsjl) is described, then an example of [usage with POMDPs.jl](#usage-with-pomdpsjl), and finally a list of the different [filters and beliefs](#types-of-filters-and-beliefs) along with brief discussion of [random number generation and resampling](#resampling) is given.

## Usage without POMDPs.jl

ParticleFilters.jl uses a simple interface consisting of the functions [`generate_s(model, state, control, rng)`](http://juliapomdp.github.io/POMDPs.jl/latest/api/#POMDPs.generate_s) and [`observation(model, control, state)`](http://juliapomdp.github.io/POMDPs.jl/latest/api/#POMDPs.observation) borrowed from [POMDPs.jl](https://github.com/JuliaPOMDP/POMDPs.jl). `generate_s()` should return the next state given the current state and control input; `observation()` should return the observation distribution for a state. If it is difficult to write the observation distribution, the shortcut function `ParticleFilters.obs_weight(model, control, state, observation)` that returns the weight (pdf) for the observation given the state and control can be implemented instead.

Once these two functions have been implemented to define the system dynamics and observation model, the function `update(filter, b, a, o)` can then be used to carry out a single update of the particle filter. It will return a `ParticleCollection` representing the belief at the next time step.

The arguments are
- `filter`: a particle filter from this package
- `b`: a belief about the system state (for example a `ParticleCollection` or a distribution from Distributions.jl),
- `a`: a control input
- `o`: an observation or measurement

`a` and `o` can be any type (but must of course be consistent with `generate_s` and `observation`. See [filters and beliefs](#filters-and-beliefs) for more information about.

For example, a double integrator model (written for clarity, not speed) is shown below.

```julia
using ParticleFilters
using Distributions
using Reel
using Plots

struct DblIntegrator2D 
    W::Matrix{Float64} # Process noise covariance
    V::Matrix{Float64} # Observation noise covariance
    dt::Float64        # Time step
end
# state is [x, y, xdot, ydot];

# generates a new state from current state s and control a
function ParticleFilters.generate_s(model::DblIntegrator2D, s, u, rng::AbstractRNG)
    dt = model.dt
    A = [1.0 0.0 dt 0.0; 0.0 1.0 0.0 dt; 0.0 0.0 1.0 0.0; 0.0 0.0 0.0 1.0]
    B = [0.5*dt^2 0.0; 0.0 0.5*dt^2; dt 0.0; 0.0 dt]
    return A*s + B*u + rand(rng, MvNormal(model.W))
end

# returns the observation distribution for state sp (and action a)
function ParticleFilters.observation(model::DblIntegrator2D, u, sp)
    return MvNormal(sp[1:2], model.V)
end

N = 1000
model = DblIntegrator2D(0.001*eye(4), eye(2), 0.1)
filter = SIRParticleFilter(model, N)
srand(1)
rng = Base.GLOBAL_RNG
b = ParticleCollection([4.0*rand(4)-2.0 for i in 1:N])
s = [0.0, 1.0, 1.0, 0.0]
film = roll(fps=10, duration=10) do t, dt
    global b, s; print(".")
    m = mean(b)
    u = [-m[1], -m[2]] # try to orbit the origin
    s = generate_s(model, s, a, rng)
    o = rand(observation(model, a, s))
    b = update(filter, b, a, o)

    scatter([p[1] for p in particles(b)], [p[2] for p in particles(b)], color=:black, markersize=0.1, label="")
    scatter!([s[1]], [s[2]], color=:blue, xlim=(-5,5), ylim=(-5,5), title=t, label="")
end
write("particles.gif", film)
```

This will produce the gif at the top of the page. Note that this could be sped up by using immutable arrays from StaticArrays.jl, and a Kalman Filter would have been much more appropriate for this linear-Gaussian case anyways.

## Usage with POMDPs.jl

ParticleFilters.jl will work out of the box with [POMDPs.jl](https://github.com/JuliaPOMDP/POMDPs.jl) models, for example with the [LightDarkPOMDP](https://github.com/zsunberg/LightDarkPOMDPs.jl).

```julia
using ParticleFilters
using LightDarkPOMDPs
using POMDPToolbox
using Reel
using Plots

pomdp = LightDark2D()
filter = SimpleParticleFilter(pomdp, LowVarianceResampler(1000))

hist = sim(pomdp, updater=filter, max_steps=50) do b::ParticleCollection
    m = mean(b)
    return 0.15*[m[2], -m[1]]
end

film = roll(fps=2, duration=length(hist)/2) do t, dt
    plot(pomdp, xlim=(-7,7), ylim=(-6,6), aspect_ratio=:equal)
    v = view(hist, 1:Int(2*t+1)); plot!(v)
    b = belief_hist(v)[end]; plot!(b, label="belief")
end
write("lightdark_particle.gif", film)
```

This should produce a gif similar to the one below.

![lightdark_particle.gif](/img/lightdark_particle.gif)

## Types of Filters and Beliefs

### Beliefs

The package provides two belief types, `ParticleCollection`, which is simply a list of states without any weights, and `WeightedParticleBelief`, which contains a vector of states and a vector of the corresponding weights. The weights in a `WeightedParticleBelief` `b` sum to `weight_sum(b)`, which is not necessarily one.

The following functions are defined for both types and constitute the interface for a particle belief `b`. Access the docstrings with `?` to see what they do.

- `n_particles(b)`
- `particles(b)`
- `weighted_particles(b)`
- `weight_sum(b)`
- `weights(b)`
- `weight(b, i)`
- `particle(b, i)`
- `rand([rng], b)`
- `iterator(b)`
- `pdf(b, s)`
- `mean(b)`
- `mode(b)`
- `sampletype(b)`

### Filters

The basic particle filter type is `SimpleParticleFilter`. The constructor takes two arguments, a model and a resampler (and an optional random number generator). Resampling behavior including the number of particles can be controlled by specifying the resampler (see below). The filter works in four steps

1. Sample states from the input belief
2. Simulate each state forward 1 time step
3. Weight each state according to it's likelihood
4. Resample from the weighted state collection and return a `ParticleCollection`

Most users should start out with the `SIRParticleFilter` (SIR = sequential importance resampling), which, in code terms, is an alias for a `SimpleParticleFilter` with a `LowVarianceResampler`. The constructor takes two arguments, a model and the number of particles (and optionally a random number generator).

There is also an `UnweightedParticleFilter` that only accepts particles that generate exactly the same observation as the true observation from the environment when simulated. This usually will not work in practice since it is very susceptible to particle depletion, but is included as a default fallback for cases when `obs_weight` is not implemented.

## Resampling

Naive resampling techniques can easily accidentally result in O(n²) algorithms. Fortunately there are lower-complexity methods for drawing a large number of samples from a distribution. These are implemented in the two resamplers included in the package:

- The `ImportanceResampler` uses the `alias_resample!` method from `StatsBase.jl`, which generates independent samples in O(n log(n)) time
- The `LowVarianceResampler` uses the method described on p. 110 of *Probabilistic Robotics* by Thrun, Bergard, and Fox to generate representative samples in O(n) time.

# Dealing with particle depletion and other problems

Particle filters generally require domain-specific tricks and modifications to overcome problems such as particle depletion. As such, ParticleFilters.jl is designed to act as a template for you to be able to create your own filters. Have a look at the default `update()` implementation in [src/ParticleFilters.jl](src/ParticleFilters.jl), and pick and choose which tools (for example the resamplers or the belief types) you use to create your own fast and efficient filters. An example of a more robust filter is located here: https://github.com/zsunberg/ContinuousPOMDPTreeSearchExperiments.jl/blob/master/src/updaters.jl#L54
