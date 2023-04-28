using Documenter, ParticleFilters, POMDPs, PlutoSliderServer

makedocs(
    modules=[ParticleFilters, POMDPs],
    format=Documenter.HTML(),
    sitename="ParticleFilters.jl"
)

PlutoSliderServer.export_directory("../notebooks"; Export_output_dir="build/notebooks")

deploydocs(
    repo="github.com/JuliaPOMDP/ParticleFilters.jl.git",
    target="build",
    deps=nothing,
    make=nothing
)
