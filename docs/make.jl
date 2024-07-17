using Documenter, ParticleFilters, POMDPs, PlutoSliderServer

makedocs(
    modules=[ParticleFilters, POMDPs],
    format=Documenter.HTML(),
    sitename="ParticleFilters.jl",
    warnonly=[:missing_docs, :cross_references],
    remotes=Dict(dirname(dirname(pathof(POMDPs))) => (Remotes.GitHub("JuliaPOMDP", "POMDPs.jl"), "v1.0.0")) # Note: this is hard-coded to version 1.0.0 because I didn't know how to fix it. It should be updated in a future release.
)

PlutoSliderServer.export_directory(
    "$(@__DIR__)/../notebooks";
    Export_output_dir="$(@__DIR__)/build/notebooks"
)

deploydocs(
    repo="github.com/JuliaPOMDP/ParticleFilters.jl.git",
)
