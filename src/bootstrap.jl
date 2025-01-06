"""
    BootstrapFilter(pomdp, n; <keyword arguments>)
    BootstrapFilter(dynamics, likelihood, n; <keyword arguments>)

Construct a standard bootstrap particle filter.

# Arguments
- `pomdp::POMDP`: A POMDP model from POMDPs.jl
- `dynamics::Function`: A function of the form `dynamics(x, u, rng)` that returns the next state, `xp`, given the current state, `x`, and the action, `u`. The random number generator, `rng`, should be used to generate any necessary randomness.
- `likelihood::Function`: A function of the form `likelihood(x, u, xp, y)` that returns the likelihood of observing `y` given `x`, `u`, and `xp`.
- `n::Integer`: number of particles

# Keyword Arguments
- `resample_threshold::Float64=0.9`: normalized ESS threshold for resampling
- `postprocess::Function=(bp, args...)->bp`: a function to apply to the belief at the end of each update step. This function should have the form `postprocess(bp, b, a, o, rng)` and should return a modified version of `bp` with any postprocessing changes made. See the Particle Depletion section of the ParticleFilters.jl documentation for more information.
- `rng::AbstractRNG=Random.default_rng()`: random number generator

For more explanation, see the Bootstrap Filter section of the ParticleFilters.jl package documentation. For a more flexible particle filter structure see [`BasicParticleFilter`](@ref).
"""
function BootstrapFilter end # for docs

function BootstrapFilter(m::POMDP, n::Int; resample_threshold=0.9, postprocess=(bp, args...)->bp, rng::AbstractRNG=Random.default_rng())
    return BasicParticleFilter(
        NormalizedESSConditionalResampler((b, a, o, rng) -> low_variance_sample(b, n, rng), resample_threshold),
        POMDPPredicter(m),
        POMDPReweighter(m),
        PostprocessChain(postprocess, check_particle_belief),
        initialize=(d, rng)->initialize_to(WeightedParticleBelief, n, d, rng),
        rng=rng
    )
end

function BootstrapFilter(dynamics::Function, likelihood::Function, n::Int; resample_threshold=0.9, postprocess=(bp, args...)->bp, rng::AbstractRNG=Random.default_rng())
    return BasicParticleFilter(
        NormalizedESSConditionalResampler((b, a, o, rng) -> low_variance_sample(b, n, rng), resample_threshold),
        BasicPredictor(dynamics),
        BasicReweighter(likelihood),
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
