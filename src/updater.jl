initialize_belief{S}(up::SimpleParticleFilter{S}, d::Any) = resample(up.resample, d, S, up.rng)

resample(f::Function, d::Any, rng::AbstractRNG) = f(d, rng)
