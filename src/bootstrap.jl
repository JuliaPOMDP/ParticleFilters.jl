"""
    BootstrapFilter(model, n, [rng])

Construct a standard bootstrap particle filter.

The Bootstrap filter was first described in Gordon, N. J., Salmond, D. J., & Smith, A. F. M. "Novel approach to nonlinear / non-Gaussian Bayesian state estimation", with the added robustness of the LowVarianceResampler.

# Arguments
- `model`: a model for the prediction dynamics and likelihood reweighing, for example a `POMDP` or `ParticleFilterModel`
- `n::Integer`: number of particles
- `rng::AbstractRNG`: random number generator

For a more flexible particle filter structure see [`BasicParticleFilter`](@ref).
"""
function BootstrapFilter(model, n::Int, rng::AbstractRNG=Random.GLOBAL_RNG)
    return BasicParticleFilter(model, LowVarianceResampler(n), n, rng)
end
