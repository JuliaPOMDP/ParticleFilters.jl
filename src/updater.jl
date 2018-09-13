initialize_belief(up::SimpleParticleFilter{S}, d::Any) where {S} = resample(up.resample, d, S, up.rng)

resample(f::Function, d::Any, rng::AbstractRNG) = f(d, rng)
