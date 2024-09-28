struct BasicPredictor{F<:Function} <: Function
    dynamics::F
end

BasicPredictor(m::ParticleFilterModel) = BasicPredictor(m.f)

# """
#     Predictor(f::Function)
# 
# Create a prediction model for use in a [`BasicParticleFilter`](@ref)
# 
# See [`ParticleFilterModel`](@ref) 
# """
# PredictModel{S}(f::F) where {S, F<:Function} = PredictModel{S, F}(f)

# function predict(pm, m::PredictModel, b, u, rng)
(p::BasicPredictor)(b, u, y, rng) = map(x -> p.dynamics(x, u, rng), particles(b))

struct BasicReweighter{G<:Function} <: Function
    reweight::G
end

BasicReweighter(m::ParticleFilterModel) = Reweighter(m.g)

function (r::BasicReweighter)(b, u, ps, y)
    map(1:length(ps)) do i
        x1 = particle(b, i)
        x2 = ps[i]
        r.reweight(x1, u, x2, y)
    end
end


# """
#     ReweightModel(g::Function)
# 
# Create a reweighting model for us in a [`BasicParticleFilter`](@ref).
# 
# See [`ParticleFilterModel`](@ref) for a description of `g`.
# """
# struct ReweightModel{G}
#     g::G
# end
# 
# function reweight!(wm, m::ReweightModel, b, u, pm, y)
#     for i in 1:n_particles(b)
#         x1 = particle(b, i)
#         x2 = pm[i]
#         wm[i] = m.g(x1, u, x2, y)
#     end
# end

struct ParticleFilterModel{S, F, G}
    f::F
    g::G
end


# TODO (?) Deprecate ParticleFilterModel

"""
    ParticleFilterModel{S}(f, g)

Create a system model suitable for use in a particle filter. This is a combination prediction/dynamics model and reweighting model.

# Parameters
- `S` is the state type, e.g. `Float64`, `Vector{Float64}`

# Arguments
- `f` is the dynamics function. `xₜ₊₁ = f(xₜ, uₜ, rng)` where `x` is the state, `u` is the control input, and `rng` is a random number generator.
- `g` is the observation weight function. `g(xₜ, uₜ, xₜ₊₁, yₜ₊₁)` returns the likelihood weight of measurement yₜ₊₁ given that the state transitioned from `xₜ` to `xₜ₊₁` when control uₜ was applied. These weights need not be normalized (and, for performance, usually should not be).
"""
function ParticleFilterModel{S}(f::F, g::G) where {S, F<:Function, G<:Function}
    return ParticleFilterModel{S, F, G}(f, g)
end

function predict!(pm, m::ParticleFilterModel{S}, b, u, rng) where S
    predict!(pm, PredictModel{S}(m.f), b, u, rng)
end

function reweight!(wm, m::ParticleFilterModel, b, u, pm, y)
    reweight!(wm, ReweightModel(m.g), b, u, pm, y)
end

particle_memory(m::ParticleFilterModel{S}) where S = S[]
