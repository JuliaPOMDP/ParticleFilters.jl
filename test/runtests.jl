using ParticleFilters
using POMDPs
using POMDPModels
using POMDPLinter: @implemented
using Test
using POMDPPolicies
using POMDPSimulators
using POMDPModelTools
using Random
using Distributions
using NBInclude

struct P <: POMDP{Nothing, Nothing, Nothing} end
ParticleFilters.obs_weight(::P, ::Nothing, ::Nothing, ::Nothing, ::Nothing) = 1.0

@testset "implemented" begin
    @test @implemented obs_weight(::P, ::Nothing, ::Nothing, ::Nothing, ::Nothing)
    @test obs_weight(P(), nothing, nothing, nothing, nothing) == 1.0
end

include("example.jl")
include("domain_specific_resampler.jl")
include("beliefs.jl")

struct ContinuousPOMDP <: POMDP{Float64, Float64, Float64} end
@testset "infer" begin
    p = TigerPOMDP()
    filter = BootstrapFilter(p, 10000)
    Random.seed!(filter, 47)
    b = @inferred initialize_belief(filter, initialstate(p))
    @testset "sir" begin
        m = @inferred mode(b)
        m = @inferred mean(b)
        it = @inferred support(b)
        @inferred weighted_particles(b)
    end
    @testset "lowvar" begin
        rs = LowVarianceResampler(1000)
        @inferred resample(rs, b, MersenneTwister(3))
        ps = particles(b)
        ws = ones(length(ps))
        @inferred resample(rs, WeightedParticleBelief(ps, ws, sum(ws)), MersenneTwister(3))
        @inferred resample(rs, WeightedParticleBelief{Bool}(ps, ws, sum(ws), nothing), MersenneTwister(3))
    end
    # test that the special method for ParticleCollections works
    @testset "collection" begin
        rs = LowVarianceResampler(1000)
        b = ParticleCollection(1:1000)
        rb1 = @inferred resample(rs, b, MersenneTwister(3))
        rb2 = @inferred resample(rs, WeightedParticleBelief(particles(b), ones(n_particles(b))), MersenneTwister(3))
        @test all(particles(rb1).==particles(rb2))
    end

    @testset "unweighted" begin
        rng = MersenneTwister(47)
        uf = UnweightedParticleFilter(p, 1000, rng)
        ps = @inferred initialize_belief(uf, initialstate(p))
        a = @inferred rand(rng, actions(p))
        sp, o = @inferred @gen(:sp, :o)(p, rand(rng, ps), a, rng)
        bp = @inferred update(uf, ps, a, o)

        wp1 = @inferred collect(weighted_particles(ParticleCollection([1,2])))
        wp2 = @inferred collect(weighted_particles(WeightedParticleBelief([1,2], [0.5, 0.5])))
        @test wp1 == wp2
    end

    @testset "normal" begin
        pf = BootstrapFilter(ContinuousPOMDP(), 100)
        ps = @inferred initialize_belief(pf, Normal())
    end
end

struct TerminalPOMDP <: POMDP{Int, Int, Float64} end
POMDPs.isterminal(::TerminalPOMDP, s) = s == 1
POMDPs.observation(::TerminalPOMDP, a, sp) = Normal(sp)
POMDPs.transition(::TerminalPOMDP, s, a) = Deterministic(s+a)
@testset "pomdp terminal" begin
    pomdp =  TerminalPOMDP()
    pf = BootstrapFilter(pomdp, 100)
    bp = update(pf, initialize_belief(pf, Categorical([0.5, 0.5])), -1, 1.0)
    @test all(particles(bp) .== 1)
end

@testset "alpha" begin
    # test specific method for alpha vector policies and particle beliefs
    pomdp = BabyPOMDP()
    # the first two alphas were gotten from FIB.jl; the third is from always feeding (see #46)
    alphas = [[-16.0629, -36.5093], [-19.4557, -29.4557], [-50.0, -60.0]]
    amap = collect(ordered_actions(pomdp))
    push!(amap, true)
    policy = AlphaVectorPolicy(pomdp, alphas, amap)

    # initial belief is 100% confidence in baby being hungry
    b = ParticleCollection([true for i=1:100])

    # because baby is hungry, policy should feed (return true)
    @test action(policy, b) == true
    @test isapprox(value(policy, b), -29.4557)
end


is_ci = get(ENV, "CI", "false") == "true"
is_travis = get(ENV, "TRAVIS", "false") == "true"

@show is_ci
@show is_travis

@warn("Notebook smoke testing is disabled on JuliaCI. We should re-enable it asap")

if !is_ci || is_travis
    @testset "data series" begin
        cd("../notebooks") do
            @nbinclude("../notebooks/Filtering-a-Trajectory-or-Data-Series.ipynb")
        end
    end

    @testset "feedback" begin
        @nbinclude("../notebooks/Using-a-Particle-Filter-for-Feedback-Control.ipynb"; softscope=true)
    end

    @testset "pomdps" begin
        @nbinclude("../notebooks/Using-a-Particle-Filter-with-POMDPs-jl.ipynb")
    end
end
