using ParticleFilters
using POMDPs
using POMDPModels
using Base.Test

import ParticleFilters: obs_weight
import POMDPs: observation

struct P <: POMDP{Void, Void, Void} end

@test !@implemented obs_weight(::P, ::Void, ::Void, ::Void, ::Void)
@test !@implemented obs_weight(::P, ::Void, ::Void, ::Void)
@test !@implemented obs_weight(::P, ::Void, ::Void)

obs_weight(::P, ::Void, ::Void, ::Void) = 1.0
@test @implemented obs_weight(::P, ::Void, ::Void, ::Void)
@test @implemented obs_weight(::P, ::Void, ::Void, ::Void, ::Void)
@test !@implemented obs_weight(::P, ::Void, ::Void)

@test obs_weight(P(), nothing, nothing, nothing, nothing) == 1.0

observation(::P, ::Void) = nothing
@test @implemented obs_weight(::P, ::Void, ::Void)

include("example.jl")

p = TigerPOMDP()
filter = SIRParticleFilter(p, 100)
srand(filter, 47)
b = initialize_belief(filter, initial_state_distribution(p))
m = mode(b)
m = mean(b)
it = iterator(b)
weighted_particles(b)

rng = MersenneTwister(47)
uf = UnweightedParticleFilter(p, 1000, rng)
ps = initialize_belief(uf, initial_state_distribution(p))
a = rand(rng, actions(p))
sp, o = generate_so(p, rand(rng, ps), a, rng)
bp = update(uf, ps, a, o)
