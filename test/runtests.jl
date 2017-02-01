using ParticleFilters
using Base.Test
using POMDPToolbox

using LightDarkPOMDPs
using ContinuousPOMDPTreeSearchExperiments

pomdp = LightDark2D(init_dist=SymmetricNormal2([2.0, 2.0], 5.0))

policy = SimpleFeedback(gain=0.1)

fnew = SIRParticleFilter(pomdp, 100)
roll = RolloutSimulator(rng=MersenneTwister(1), max_steps=10)
simulate(roll, pomdp, policy, fnew)

policy = FunctionPolicy(s->Vec2([0.0, 0.0]))
fnew = SimpleParticleFilter(pomdp, LowVarianceResampler(1000))
is = Vec2([5.2, 0.0])
hr = HistoryRecorder(initial_state=is, max_steps=10)
hist = simulate(hr, pomdp, policy, fnew)
@test norm(mean(last(belief_hist(hist)))-is) <= 0.5
