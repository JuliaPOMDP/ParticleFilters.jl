"""
    BootstrapFilter(model, n, [rng])

Construct a standard bootstrap particle filter.

The Bootstrap filter was first described in Gordon, N. J., Salmond, D. J., & Smith, A. F. M. "Novel approach to nonlinear / non-Gaussian Bayesian state estimation", with the added robustness of the LowVarianceResampler.

TODO: update with ess

# Arguments
- `model`: a model for the prediction dynamics and likelihood reweighing, for example a `POMDP` or `ParticleFilterModel`
- `n::Integer`: number of particles
- `rng::AbstractRNG`: random number generator

For a more flexible particle filter structure see [`BasicParticleFilter`](@ref).
"""
function BootstrapFilter(m::POMDP, n::Int, resample_threshold=0.9, postprocess=(bp, args...)->bp, rng::AbstractRNG=Random.TaskLocalRNG())
    return BasicParticleFilter(
        NormalizedESSConditionalResample(LowVarianceResampler(n), normalized_ess),
        POMDPPredictor(m),
        POMDPReweighter(m),
        PostprocessChain(postprocess, check_particle_belief),
        rng
    )
end

function BootstrapFilter(m::ParticleFilterModel, n::Int, resample_threshold=0.9, postprocess=(bp, args...)->bp, rng::AbstractRNG=Random.TaskLocalRNG())
    return BasicParticleFilter(
        NormalizedESSConditionalResample(LowVarianceResampler(n), normalized_ess),
        BasicPredictor(m),
        BasicReweighter(m),
        PostprocessChain(postprocess, check_particle_belief),
        rng
    )
end
