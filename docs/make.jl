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
    pages = page_order,
)

deploydocs(
    repo="github.com/JuliaPOMDP/ParticleFilters.jl.git",
    push_preview = true,
    devbranch = "master",
    # the manual versions below is a hack... hopefully some day it can get removed
    versions = ["stable" => "v0.6.1",
                "dev" => "master",
                "v0.6",
                "v0.5",
                "v0.4",
                "v0.3"],
)
