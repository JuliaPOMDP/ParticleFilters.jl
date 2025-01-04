function BootstrapFilter(m::ParticleFilterModel, n::Int; resample_threshold=0.9, postprocess=(bp, args...)->bp, rng::AbstractRNG=Random.default_rng())
    return BasicParticleFilter(
        NormalizedESSConditionalResampler(LowVarianceResampler(n), resample_threshold),
        BasicPredictor(m),
        BasicReweighter(m),
        PostprocessChain(postprocess, check_particle_belief),
        initialize=(d, rng)->initialize_to(WeightedParticleBelief, n, d, rng),
        rng=rng
    )
end


