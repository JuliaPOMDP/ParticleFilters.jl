function initialize_belief(up::SimpleParticleFilter{S}, d::Any) where {S}
    resample(up.resample, d, up.rng)
end

function initialize_belief(up::SimpleParticleFilter{S,<:Any,R}, d::Any) where {S, R<:Union{LowVarianceResampler, ImportanceResampler}}
    resample(up.resample, d, S, up.rng)
end

resample(f::Function, d::Any, rng::AbstractRNG) = f(d, rng)
