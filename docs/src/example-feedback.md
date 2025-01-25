# Example: Feedback Control

In this tutorial, we will give a brief example of how to use a Particle Filter from `ParticleFilters.jl` for feedback control.

```@example feedback
using ParticleFilters
using Distributions
using StaticArrays
using LinearAlgebra
using Random
using Plots
```

## System Description

The system is a two-dimensional discrete-time double integrator with gaussian process and observation noise. The state at time $k$, $x_k$, is a 4-element vector consisting of the position in two dimensions and the velocity. The dynamics can be represented with the linear difference equation:

$$x_{k+1} = f(x_k, u_k, w_k) = A x_k + B u_k + w_k \text{,}$$

where $w_k$ are independent but identically-distributed zero-mean Gaussian random variables with covariance matrix $W$. $A$ and $B$ are given in the code below.

The measurements are noisy observations of the position generated according to 

$$y_{k+1} = h(x_k, u_k, x_{k+1}, v_{k+1}) = C x_{k+1} + v_{k+1} \text{,}$$

where $C$ selects only the position of the model, and $v_k$ are independent identically-distributed zero-mean Gaussian random variables with covariance matrix $V$.

## Control Law Description

The control law, will use the mean from the particle filter belief to try to make the state oscillate about the origin, i.e.

$$u = K \hat{x}$$

where $\hat{x}$ is the mean estimate of the state, and

$$K = [-1, -1, 0, 0]$$

It should be noted that, since this system is linear with Gaussian noise, a [Kalman Filter](https://en.wikipedia.org/wiki/Kalman_filter) would be much better-suited for this case, but we use the system here for its simplicity. In general, particle filters can be used with any nonlinear dynamical systems.

## Dynamics model

We begin by defining the dynamics of the system. For more information about defining a model, see the ["Models" section of the documentation](https://juliapomdp.github.io/ParticleFilters.jl/latest/models/).

```@example feedback
const dt = 0.1; # time step

const A = [1.0 0.0 dt  0.0;
           0.0 1.0 0.0 dt ;
           0.0 0.0 1.0 0.0;
           0.0 0.0 0.0 1.0];

const B = [0.5*dt^2 0.0     ;
           0.0      0.5*dt^2;
           dt       0.0     ;
           0.0      dt      ];

const W = 0.3*Matrix(0.01*Diagonal{Float64}(I, 4)); # Process noise covariance

const V = 0.3*Matrix(Diagonal{Float64}(I, 2)); # Measurement noise covariance

f(x, u, rng) = A*x + B*u + rand(rng, MvNormal(W));
```

## Observation Model

Next, the observation model is defined. $h$ generates an observation (this is only used in the simulation, not in the particle filter), $g$ returns the relative likelyhood of an observation given the previous state, control, and current state.

```@example feedback
h(x, rng) = rand(rng, MvNormal(x[1:2], V));

g(x0, u, x, y) = pdf(MvNormal(x[1:2], V), y);
```

## Particle Filter

We can combine the dynamics and observation model to create a particle filter.

```@example feedback
N = 1000; # Number of particles

filter = BootstrapFilter(f, g, N);
```

## Running a Simulation

To run a simulation, first an initial belief and initial state need to be created. The initial beleif will consist of particles selected uniformly from $[-2, 2]^4$.

The simulation consists of a loop in which the control is calculated from the mean of the particle. Then the state is updated with the dynamics and a new measurement is generated. Finally, the filter is used to update the belief based on this new measurement.

Using the `update` function in this interactive fashion allows the particle  filter to be used as an estimator/observer for feedback control.

```@example feedback
rng = Random.default_rng();
b = ParticleCollection([4.0*rand(4).-2.0 for i in 1:N]); # initial belief
x = [0.0, 1.0, 1.0, 0.0]; # initial state

@gif for i in 1:100
    local m = mean(b)
    u = [-m[1], -m[2]] # Control law - try to orbit the origin
    global x = f(x, u, rng)
    y = h(x, rng)
    global b = update(filter, b, u, y)

    plt = scatter([p[1] for p in particles(b)], [p[2] for p in particles(b)], color=:black, markersize=2, alpha=sqrt.(weights(b)./weight_sum(b)), label="")
    scatter!(plt, [x[1]], [x[2]], color=:blue, xlim=(-5,5), ylim=(-5,5), label="")
end
```
