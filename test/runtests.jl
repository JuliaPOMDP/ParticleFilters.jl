using ParticleFilters
using POMDPs
using POMDPModels
using POMDPToolbox
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

wp1 = collect(weighted_particles(ParticleCollection([1,2])))
wp2 = collect(weighted_particles(WeightedParticleBelief([1,2], [0.5, 0.5])))
@test wp1 == wp2

# test specific method for alpha vector policies and particle beliefs
pomdp = BabyPOMDP()
# these values were gotten from FIB.jl
alphas = [-29.4557 -36.5093; -19.4557 -16.0629]
policy = AlphaVectorPolicy(pomdp, alphas)

# initial belief is 100% confidence in baby being hungry
b = ParticleCollection([true for i=1:100])

# because baby is hungry, policy should feed (return true)
@test action(policy, b) == true
@test isapprox(value(policy, b), -29.4557)
