using Documenter, ParticleFilters, POMDPs, PlutoSliderServer

page_order = [
    "index.md",
    "bootstrap.md",
    "beliefs.md",
    "basic.md",
    "depletion.md",
    "sampling.md",
]

makedocs(
    modules=[ParticleFilters, POMDPs],
    format=Documenter.HTML(),
    sitename="ParticleFilters.jl",
    warnonly = [:missing_docs, :cross_references],
    pages = page_order
)

PlutoSliderServer.export_directory(
    "$(@__DIR__)/../notebooks";
    Export_output_dir="$(@__DIR__)/build/notebooks"
)

deploydocs(
    repo="github.com/JuliaPOMDP/ParticleFilters.jl.git",
    target="build",
    push_preview = true,
)
