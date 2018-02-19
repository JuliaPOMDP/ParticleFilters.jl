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
b = @inferred initialize_belief(filter, initial_state_distribution(p))
m = @inferred mode(b)
m = @inferred mean(b)
it = @inferred iterator(b)
@inferred weighted_particles(b)

rs = LowVarianceResampler(100)
@inferred resample(rs, b, MersenneTwister(3))
ps = particles(b)
ws = ones(length(ps))
@inferred resample(rs, WeightedParticleBelief(ps, ws, sum(ws)), MersenneTwister(3))
@inferred resample(rs, WeightedParticleBelief{Bool}(ps, ws, sum(ws), nothing), MersenneTwister(3))

rng = MersenneTwister(47)
uf = UnweightedParticleFilter(p, 1000, rng)
ps = @inferred initialize_belief(uf, initial_state_distribution(p))
a = @inferred rand(rng, actions(p))
sp, o = @inferred generate_so(p, rand(rng, ps), a, rng)
bp = @inferred update(uf, ps, a, o)

wp1 = @inferred collect(weighted_particles(ParticleCollection([1,2])))
wp2 = @inferred collect(weighted_particles(WeightedParticleBelief([1,2], [0.5, 0.5])))
@test wp1 == wp2
