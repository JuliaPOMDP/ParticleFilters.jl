# Handling Particle Depletion

Many of the most common problems with particle filters are related to particle depletion, that is, a lack of particles corresponding to the true state. In many cases, it is not difficult to overcome these problems, but domain-specific heuristics are often more effective than generic approaches.

The recommended way to handle particle depletion in a [`BootstrapFilter`](@ref) or [`BasicParticleFilter`](@ref) is to add a postprocessing step. In the `BasicParticleFilter`, this is a required argument; in the `BootstrapFilter`, it is an optional keyword argument.

A postprocessing function takes 6 arguments:
```julia
postprocess(bp, a, o, b, bb, rng)
```
`bp` is the new belief, `a` is the action, `o` is the observation, `b` is the old belief, `bb` is the belief after preprocessing, and `rng` is the random number generator. See the [Basic Particle Filter](@ref) section to see where `postprocess` is called in the code. The postprocessing function should return the modified belief. This can be the same object `bp` modified in place or a new object.

!!! tip
    If you don't need all of the arguments, you can use the splat operator `...` to ignore them, e.g. `postprocess(bp, a, o, args...)`.

!!! tip
    The function does not need to be named `postprocess`. It can have any name or be anonymous.

Creating a postprocessing function is best illustrated by a simple example:

## Example

In this example, we have a system with integer states states and actions, deterministic dynamics, and an observation that is uniformly distributed over the current state plus or minus 1. If all state particles start 1, action 1 is taken, and observation 4 is received, then no particles are consistent with the observation. This will yield a warning about particle depletion and produce a belief with zero-weighted particles that cannot be sampled from or used effectively: 

```@example depletion
using ParticleFilters, Distributions

dynamics(s, a, rng) = s + a
likelihood(s_previous, a, s, o) = abs(o - s) <= 1
naive_pf = BootstrapFilter(dynamics, likelihood, 3)

b0 = ParticleCollection([1, 1, 1])
a = 1
o = 4

bp = update(naive_pf, b0, a, o)
nothing # hide
```

To fix this, we define a postprocessing step to refill the particle belief with particles consistent with the observation:

```@example depletion
function refill_with_consistent(bp, a, o, b, bb, rng)
    if weight_sum(bp) == 0.0
        return WeightedParticleBelief([o-1, o, o+1], ones(3))
    else
        return bp
    end
end
nothing # hide
```

Note that this solution is *very* domain-specific. It relies on specific knowledge about the observation function. In other applications, you will likely need to be clever about coming up with ways to create replacement particles in cases of depletion.
Armed with the new postprocessing step, we can create a new filter and use it for a belief update:

```@example depletion
pf = BootstrapFilter(dynamics, likelihood, 3; postprocess=refill_with_consistent)
bp = update(pf, b0, a, o)
```

While this new belief is consistent with the observation, it does not take into account the dynamics or information from the previous steps. A better solution might be to populate the new belief with particles as near as possible to the previous particles while still being consistent with the observation. Tricks like this are often necessary to get good performance in practice and they are an important part of the art of particle filtering.

## Additional Examples of Postprocessing Functions

The following section provides additional examples of strategies that commonly work well and additional postprocessing functions.

### Replacing Zero-Weight Particles

Rather than waiting until all particle weights are zero, it is often effective to replace zero-weight particles as soon as they are detected. If a function `consistent_state(o, rng)` is written to generate states consistent with the observation, this replacement can be accomplished with the following postprocessing function:

```julia
function replace_zero_weight_particles(bp, a, o, b, bb, rng)

    n = n_particles(bp)
    new_weight = weight_sum(bp)/n

    for i in 1:n
        if weight(bp, i) == 0.0
            s = consistent_state(o, rng)
            set_pair!(bp, i, s => new_weight)
        end
    end

    return bp
end
```

### Adding Artificial Noise

In continuous-state systems with deterministic dynamics, it can be useful to add artificial noise to the states as follows:

```julia
function add_noise(bp, a, o, b, bb, rng)
    for i in 1:n_particles(bp)
        p = particle(bp, i)
        set_particle!(bp, i, p + 0.1*randn(rng))
    end
    return bp
end
```

### Combining Multiple Postprocessing Steps

It is often useful to combine multiple postprocessing steps. This can be accomplished convenienttly with the `PostprocessChain` function:

```
PostprocessChain(replace_zero_weight_particles, add_noise)
```

### Replacing Zero-Weight Particles with States from the Initial Distribution

If no other information is available, a quick solution is to replace zero-weight particles with states drawn from the initial distribution. In POMDPs.jl, the `initialstate` function can be used to generate these states. This implementation uses a callable object to store the POMDP model.

```jldoctest replace_with_initial; output=false
using ParticleFilters, POMDPs, POMDPModels

struct ReplaceWithInitial{M <: POMDP} <: Function
    m::M
    threshold::Float64 # replace particles with normalized weights below this
end

function (r::ReplaceWithInitial)(bp, a, o, b, bb, rng)
    ws = weights(bp)
    wsum = weight_sum(bp)
    nws = ws ./ wsum
    n = n_particles(bp)
    for i in 1:n
        if nws[i] < r.threshold
            set_pair!(bp, i, rand(rng, initial_state(r.m)) => wsum/n)
        end
    end
    return bp
end

# output

```

The filter can then be created as follows:

```jldoctest replace_with_initial; output=false, filter=r"BasicParticleFilter.*"=>s"BasicParticleFilter"
m = TigerPOMDP()
pf = BootstrapFilter(m, 1, postprocess=ReplaceWithInitial(m, 0.1))

# output

BasicParticleFilter()
```
