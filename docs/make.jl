using Documenter, ParticleFilters, POMDPs, PlutoSliderServer

makedocs(
    modules=[ParticleFilters, POMDPs],
    format=Documenter.HTML(),
    sitename="ParticleFilters.jl",
    warnonly=[:missing_docs, :cross_references]
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
