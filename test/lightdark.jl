using Base.Test
using POMDPToolbox

using LightDarkPOMDPs

pomdp = LightDark2D(init_dist=SymmetricNormal2([2.0, 2.0], 5.0))

policy = FunctionPolicy(s->-0.1*mean(s))

fnew = SIRParticleFilter(pomdp, 100, rng=MersenneTwister(42))
ro = RolloutSimulator(rng=MersenneTwister(1), max_steps=10)
simulate(ro, pomdp, policy, fnew)

policy = FunctionPolicy(s->Vec2([0.0, 0.0]))
fnew = SimpleParticleFilter(pomdp, LowVarianceResampler(1000), rng=MersenneTwister(3))
is = Vec2([5.2, 0.0])
hr = HistoryRecorder(initial_state=is, max_steps=10, rng=MersenneTwister(3))
hist = simulate(hr, pomdp, policy, fnew)
@test norm(mean(last(belief_hist(hist)))-is) <= 0.5
