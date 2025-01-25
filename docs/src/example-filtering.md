# Example: Filtering Preexisting Data

In some cases, there is no need to perform control based on the particle belief and instead the goal is to filter a previously-generated sequence of measurements to remove noise or reconstruct hidden state variables. This tutorial will illustrate use of the `runfilter` function for that purpose.

First, we import the packages we will use. 

```@example filtering
using Distributions
using Random
using DelimitedFiles
using ParticleFilters
using VegaLite
```

## Model

We will use [Euler-integrated](https://en.wikipedia.org/wiki/Euler_method) [Van Der Pol Oscillator Equations](https://en.wikipedia.org/wiki/Van_der_Pol_oscillator) with noise added as the dynamics (`f`), and measurements of the position with gaussian noise added (the pdf is encoded in `g`).

This model is implemented below. For more information on defining models for particle filters, see the [documentation](https://juliapomdp.github.io/ParticleFilters.jl/latest/models/).

```@example filtering
const dt = 0.2
const mu = 0.8
const sigma = 1.0

function f(x, u, rng)
    xdot = [x[2], mu * (1 - x[1]^2) * x[2] - x[1] + u + 0.1 * randn(rng)]
    return x + dt * xdot
end

g(x1, u, x2, y) = pdf(Normal(sigma), y - x2[1])
nothing # hide
```

## Data

Suppose that the data we would like to filter are contained in text files. [`u.txt`](u.txt) contains the control inputs, and [`y.txt`](y.txt) contains the measurements. The code that generated this data can be found in the [appendix below](#Appendix).

```@example filtering
ys = vec(readdlm("y.txt"));
us = vec(readdlm("u.txt"));
nothing # hide
```

## Filtering

We can use an SIR particle filter to get a better estimate of the state. Note that we start with an initial belief consisting of particles with zero velocity and position uniformly distributed in $[-5, 5]$.

```@example filtering
n = 10_000

fil = BootstrapFilter(f, g, n)

# construct initial belief
b0 = ParticleCollection([[10.0 * (rand() - 0.5), 0.0] for i in 1:n])

bs = runfilter(fil, b0, us, ys)
```

## Plotting the Results

We can now plot the observations, the smoothed estimate of the position (the mean of the belief at every time step), and the true state. Note that the estimated position is much closer to the true position than the noisy measurements.

```@example filtering
xmat = readdlm("x.txt");

plot_data = [(; t, x1=x[1], x2=x[2], y, b_mean=mean(b)[1]) for (t, (x, y, b)) in enumerate(zip(eachslice(xmat; dims=1), ys, bs))]

plot_data |> @vlplot(x = :t, width = 700) +
             @vlplot(:line, y = :x1, color = {datum = "True State"}) +
             @vlplot(:point, y = :y, color = {datum = "Observation"}) +
             @vlplot(:line, y = :b_mean, color = {datum = "Mean Belief"})
```

## Appendix

### Code for Generating Data

The following code can be used to generate the data in the text files:

```julia
rng = MersenneTwister(1)

k = 100
h(x, rng) = x[1] + sigma*randn(rng)

x = [3.0, 0.0]
xs = Array{typeof(x)}(undef, k)
us = zeros(k)
ys = zeros(k)
for t in 1:k
    x = f(x, us[t], rng)
    ys[t] = h(x, rng)
    xs[t] = x
end

using DelimitedFiles
writedlm("x.txt", xs)
writedlm("y.txt", ys)
writedlm("u.txt", us)
```
