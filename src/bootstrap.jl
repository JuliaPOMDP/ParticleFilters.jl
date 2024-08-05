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
function BootstrapFilter(m::POMDP, n::Int, normalized_ess::Float64, postprocess=, rng::AbstractRNG=Random.TaskLocalRNG())
    return BasicParticleFilter(
        NormalizedESSConditional(LowVarianceResampler(n), normalized_ess),
        POMDPPredictor(m),
        POMDPReweighter(m),
        postprocess,
        rng
    )
end

function BootstrapFilter(m::ParticleFilterModel, n::Int, normalized_ess, rng::AbstractRNG=Random.TaskLocalRNG())
    return BasicParticleFilter(
        NormalizedESSConditional(LowVarianceResampler(n), normalized_ess),
        BasicPredictor(m),
        BasicReweighter(m),
        check_weights_positive,
        rng
    )
end
