using Documenter, ParticleFilters, POMDPs

page_order = [
    "index.md",
    "bootstrap.md",
    "beliefs.md",
    "basic.md",
    "depletion.md",
    "sampling.md",
    "example-filtering.md",
    "example-feedback.md",
    "example-pomdps.md",
]

makedocs(
    modules=[ParticleFilters, POMDPs],
    format=Documenter.HTML(),
    sitename="ParticleFilters.jl",
    warnonly = [:missing_docs, :cross_references],
    pages = page_order
)

deploydocs(
    repo="github.com/JuliaPOMDP/ParticleFilters.jl.git",
    target="build",
    push_preview = true,
)
