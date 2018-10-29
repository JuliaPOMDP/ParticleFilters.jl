# ParticleFilters

[![Docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://JuliaPOMDP.github.io/ParticleFilters.jl/latest)
[![Build Status](https://travis-ci.org/JuliaPOMDP/ParticleFilters.jl.svg?branch=master)](https://travis-ci.org/JuliaPOMDP/ParticleFilters.jl?branch=master)
[![codecov.io](http://codecov.io/github/JuliaPOMDP/ParticleFilters.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaPOMDP/ParticleFilters.jl?branch=master)

![particles.gif](/img/particles.gif)

This package rovides some simple generic particle filters, and may serve as a template for making custom particle filters and other updaters for POMDPs.jl.

# Installation

In Julia:

```julia
Pkg.add("ParticleFilters")
```

# Usage

There are tutorials for three ways to use the particle filters:
1. As an [estimator for feedback control](notebooks/Using-a-Particle-Filter-for-Feedback-Control.ipynb),
2. to [filter time-series measurements](notebooks/Filtering-a-Trajectory-or-Data-Series.ipynb), and
3. as an [updater for POMDPs.jl](notebooks/Using-a-Particle-Filter-with-POMDPs-jl.ipynb).

# Documentation

https://JuliaPOMDP.github.io/ParticleFilters.jl/latest
