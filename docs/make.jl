using Documenter, ParticleFilters, POMDPs

makedocs(
    modules = [ParticleFilters, POMDPs],
    format = :html,
    sitename = "ParticleFilters.jl"
)

deploydocs(
    repo = "github.com/JuliaPOMDP/ParticleFilters.jl.git",
    target = "build",
    deps = nothing,
    make = nothing
)
