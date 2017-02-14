# ParticleFilters

[![Build Status](https://travis-ci.org/zsunberg/ParticleFilters.jl.svg?branch=master)](https://travis-ci.org/zsunberg/ParticleFilters.jl)
[![Coverage Status](https://coveralls.io/repos/zsunberg/ParticleFilters.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/zsunberg/ParticleFilters.jl?branch=master)
[![codecov.io](http://codecov.io/github/zsunberg/ParticleFilters.jl/coverage.svg?branch=master)](http://codecov.io/github/zsunberg/ParticleFilters.jl?branch=master)

![particles.gif](https://github.com/zsunberg/ParticleFilters.jl/raw/master/img/particles.gif)

This package rovides some simple generic particle filters, and may serve as a template for making custom particle filters and other updaters for POMDPs.jl.

The function `update(filter, b, a, o)` where 
- `filter` is a particle filter from this package, 
- `b` is a belief about the system state (for example a particle collection),
- `a` is a control input, and 
- `o` is an observation

will return a particle collection representing the belief at the next time step. The resampling strategy can be controlled by specifying a custom function or object to resample.

# Installation

```julia
Pkg.clone("https://github.com/zsunberg/ParticleFilters.jl")
Pkg.build("ParticleFilters") # downloads some dependencies
```

# Usage

ParticleFilters.jl is designed to be used with [POMDPs.jl](https://github.com/JuliaPOMDP/POMDPs.jl), and should work with most POMDPs.jl models out of the box, for example with the [LightDarkPOMDP](https://github.com/zsunberg/LightDarkPOMDPs.jl).

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

![lightdark_particle.gif](https://github.com/zsunberg/ParticleFilters.jl/raw/master/img/lightdark_particle.gif)

You may not wish to define the entire POMDPs interface for your model. In that case, you can still use the particle filter if you just define `generate_s()` and `observation()` for your model. For example, a double integrator model (written for clarity, not speed) is shown below.

```julia
using ParticleFilters
using Distributions
using StaticArrays
using Reel
using Plots

immutable DblIntegrator2D 
    W::Matrix{Float64} # Process noise covariance
    V::Matrix{Float64} # Observation noise covariance
    dt::Float64        # Time step
end
# state is [x, y, xdot, ydot];

# generates a new state from current state s and control a
function ParticleFilters.generate_s(model::DblIntegrator2D, s, a, rng::AbstractRNG)
    dt = model.dt
    A = [1.0 0.0 dt 0.0; 0.0 1.0 0.0 dt; 0.0 0.0 1.0 0.0; 0.0 0.0 0.0 1.0]
    B = [0.5*dt^2 0.0; 0.0 0.5*dt^2; dt 0.0; 0.0 dt]
    d = MvNormal(model.W)
    return A*s + B*a + rand(rng, d)
end

# returns the observation distribution for state sp (and action a)
function ParticleFilters.observation(model::DblIntegrator2D, a, sp)
    return MvNormal(sp[1:2], model.V)
end

N = 1000
model = DblIntegrator2D(0.001*eye(4), eye(2), 0.1)
rng = MersenneTwister(1)
filter = SIRParticleFilter(model, N, rng=rng)
b = ParticleCollection([4.0*rand(rng, 4)-2.0 for i in 1:N])
s = [0.0, 1.0, 1.0, 0.0]
film = roll(fps=10, duration=10) do t, dt
    global b, s; print(".")
    m = mean(b)
    a = [-m[1], -m[2]] # try to orbit the origin
    s = generate_s(model, s, a, rng)
    o = rand(rng, observation(model, a, s))
    b = update(filter, b, a, o)

    scatter([p[1] for p in particles(b)], [p[2] for p in particles(b)], color=:black, markersize=0.1, label="")
    scatter!([s[1]], [s[2]], color=:blue, xlim=(-5,5), ylim=(-5,5), title=t, label="")
end
write("particles.gif", film)
```

This will produce the gif at the top of the page. Note that a Kalman Filter would have been much more appropriate for this linear-Gaussian case.


