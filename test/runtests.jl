using ParticleFilters
using POMDPs
using POMDPModels
using Test
using POMDPPolicies
using POMDPSimulators
using POMDPModelTools
using Random
using Distributions
using NBInclude

struct P <: POMDP{Nothing, Nothing, Nothing} end
@testset "!implemented" begin
    @test !@implemented obs_weight(::P, ::Nothing, ::Nothing, ::Nothing, ::Nothing)
    @test !@implemented obs_weight(::P, ::Nothing, ::Nothing, ::Nothing)
    @test !@implemented obs_weight(::P, ::Nothing, ::Nothing)
end
ParticleFilters.obs_weight(::P, ::Nothing, ::Nothing, ::Nothing) = 1.0

@testset "implemented" begin
    @test @implemented obs_weight(::P, ::Nothing, ::Nothing, ::Nothing)
    @test @implemented obs_weight(::P, ::Nothing, ::Nothing, ::Nothing, ::Nothing)
    @test !@implemented obs_weight(::P, ::Nothing, ::Nothing)
    @test obs_weight(P(), nothing, nothing, nothing, nothing) == 1.0
end

POMDPs.observation(::P, ::Nothing) = nothing
@test @implemented obs_weight(::P, ::Nothing, ::Nothing)

include("example.jl")
include("domain_specific_resampler.jl")

struct ContinuousPOMDP <: POMDP{Float64, Float64, Float64} end
@testset "infer" begin
    p = TigerPOMDP()
    filter = SIRParticleFilter(p, 10000)
    Random.seed!(filter, 47)
    b = @inferred initialize_belief(filter, initialstate_distribution(p))
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
        ps = @inferred initialize_belief(uf, initialstate_distribution(p))
        a = @inferred rand(rng, actions(p))
        sp, o = @inferred generate_so(p, rand(rng, ps), a, rng)
        bp = @inferred update(uf, ps, a, o)

        wp1 = @inferred collect(weighted_particles(ParticleCollection([1,2])))
        wp2 = @inferred collect(weighted_particles(WeightedParticleBelief([1,2], [0.5, 0.5])))
        @test wp1 == wp2
    end

    @testset "normal" begin
        pf = SIRParticleFilter(ContinuousPOMDP(), 100)
        ps = @inferred initialize_belief(pf, Normal())
    end
end

struct TerminalPOMDP <: POMDP{Int, Int, Float64} end
POMDPs.isterminal(::TerminalPOMDP, s) = s == 1
POMDPs.observation(::TerminalPOMDP, a, sp) = Normal(sp)
POMDPs.transition(::TerminalPOMDP, s, a) = Deterministic(s+a)
@testset "pomdp terminal" begin
    pomdp =  TerminalPOMDP()
    pf = SIRParticleFilter(pomdp, 100)
    bp = update(pf, initialize_belief(pf, Categorical([0.5, 0.5])), -1, 1.0)
    @test all(particles(bp) .== 1)
end

@testset "alpha" begin
    # test specific method for alpha vector policies and particle beliefs
    pomdp = BabyPOMDP()
    # these values were gotten from FIB.jl
    # alphas = [-29.4557 -36.5093; -19.4557 -16.0629]
    alphas = [-16.0629 -19.4557; -36.5093 -29.4557]
    policy = AlphaVectorPolicy(pomdp, alphas)

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
