using Documenter, ParticleFilters, POMDPs

makedocs(
    modules = [ParticleFilters, POMDPs],
    format = :html,
    sitename = "ParticleFilters.jl"
)

deploydocs(
    repo = "github.com/JuliaPOMDP/ParticleFilters.jl.git",
    julia = "1.0",
    osname = "linux",
    target = "build",
    deps = nothing,
    make = nothing
)
