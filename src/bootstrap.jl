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
function BootstrapFilter(m::POMDP, n::Int; resample_threshold=0.9, postprocess=(bp, args...)->bp, rng::AbstractRNG=Random.default_rng())
    return BasicParticleFilter(
        NormalizedESSConditionalResampler(LowVarianceResampler(n), resample_threshold),
        POMDPPredicter(m),
        POMDPReweighter(m),
        PostprocessChain(postprocess, check_particle_belief),
        initialize=(d, rng)->initialize_to(WeightedParticleBelief, n, d, rng),
        # initialize=(d, rng)->WeightedParticleBelief(rand(rng, d, n), fill(1.0/n, n)),
        rng=rng
    )
end

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

function initialize_to(B::Type{<:AbstractParticleBelief}, n, d::AbstractParticleBelief, rng)
    if isa(d, B) && n_particles(d) == n
        return d
    else
        return B(low_variance_resample(d, n, rng))
    end
end

function initialize_to(B::Type{<:AbstractParticleBelief}, n, d, rng)
    return B(sample_non_particle(d, n, rng))
end

function sample_non_particle(d, n, rng)
    # using weighted iterator here is more likely to be order n than just calling rand() repeatedly
    # but, this implementation is problematic and may change in the future
    D = typeof(d)
    try
        if @implemented(support(::D)) &&
            @implemented(iterate(::typeof(support(d)))) &&
            @implemented(pdf(::D, ::typeof(first(support(d)))))
                S = typeof(first(support(d)))
                particles = S[]
                weights = Float64[]
                for (s, w) in weighted_iterator(d)
                    push!(particles, s)
                    push!(weights, w)
                end
                return low_variance_resample(WeightedParticleBelief(particles, weights), n, rng)
        end
    catch ex
        if ex isa MethodError
            @warn("""
                Suppressing MethodError in ParticleFilters.jl. Please file an issue here:

                https://github.com/JuliaPOMDP/ParticleFilters.jl/issues/new

                The error was

                $(sprint(showerror, ex))
                  """, maxlog=1)
        else
            rethrow(ex)
        end
    end

    return collect(rand(rng, d) for i in 1:n)
end
