# ParticleFilters

[![Docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://JuliaPOMDP.github.io/ParticleFilters.jl/latest)
[![Build Status](https://travis-ci.org/JuliaPOMDP/ParticleFilters.jl.svg?branch=master)](https://travis-ci.org/JuliaPOMDP/ParticleFilters.jl?branch=master)
[![codecov.io](http://codecov.io/github/JuliaPOMDP/ParticleFilters.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaPOMDP/ParticleFilters.jl?branch=master)

![particles.gif](/img/particles.gif)

This package rovides some simple generic particle filters, and may serve as a template for making custom particle filters and other belief updaters. It is compatible with POMDPs.jl, but does not have to be used with that package.

# Installation

In Julia:

```julia
Pkg.add("ParticleFilters")
```

# Usage

Basic setup might look like this:
```julia
using ParticleFilters, Distributions

dynamics(x, u, rng) = x + u + randn(rng)
y_likelihood(x_previous, u, x, y) = pdf(Normal(), y - x)

model = ParticleFilterModel{Float64}(dynamics, y_likelihood)
pf = SIRParticleFilter(model, 10)
```
Then the `update` function can be used to perform a particle filter update.
```julia
b = ParticleCollection([1.0, 2.0, 3.0, 4.0])
u = 1.0
y = 3.0

b_new = update(pf, b, u, y)
```

This is a very simple example and the framework can accommodate a variety of more complex use cases. More details can be found in the documentation linked to below.

There are tutorials for three ways to use the particle filters:
1. As an [estimator for feedback control](notebooks/Using-a-Particle-Filter-for-Feedback-Control.ipynb),
2. to [filter time-series measurements](notebooks/Filtering-a-Trajectory-or-Data-Series.ipynb), and
3. as an [updater for POMDPs.jl](notebooks/Using-a-Particle-Filter-with-POMDPs-jl.ipynb).

# Documentation

https://JuliaPOMDP.github.io/ParticleFilters.jl/latest
