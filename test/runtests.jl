using ParticleFilters
using POMDPs
using POMDPModels
using POMDPLinter: @implemented
using Test
using POMDPTools
using Random
using Distributions

# TODO: test BootstrapFilter(pomdp, n, rng)

struct P <: POMDP{Nothing,Nothing,Nothing} end
ParticleFilters.obs_weight(::P, ::Nothing, ::Nothing, ::Nothing, ::Nothing) = 1.0

@testset "implemented" begin
    @test @implemented obs_weight(::P, ::Nothing, ::Nothing, ::Nothing, ::Nothing)
    @test obs_weight(P(), nothing, nothing, nothing, nothing) == 1.0
end

include("example.jl")
# include("domain_specific_resampler.jl")
include("beliefs.jl")

struct ContinuousPOMDP <: POMDP{Float64,Float64,Float64} end
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
        @inferred low_variance_resample(b, 100, Random.default_rng())
        @test all(s in support(b) for s in low_variance_resample(b, 100, Random.default_rng()))

        rs = LowVarianceResampler(1000)
        @inferred rs(b, TIGER_LISTEN, true, MersenneTwister(3))

        ps = particles(b)
        ws = ones(length(ps))
        @inferred low_variance_resample(WeightedParticleBelief(ps, ws, sum(ws)), 100, MersenneTwister(3))
        @inferred low_variance_resample(WeightedParticleBelief{Bool}(ps, ws, sum(ws), nothing), 100, MersenneTwister(3))
    end
    # test that the special method for ParticleCollections works
    @testset "collection" begin
        b = ParticleCollection(1:100)
        rb1 = @inferred low_variance_resample(b, 100, MersenneTwister(3))
        rb2 = @inferred low_variance_resample(WeightedParticleBelief(particles(b), ones(n_particles(b))), 100, MersenneTwister(3))
        @test all(rb1 .== rb2)
    end

    @testset "unweighted" begin
        rng = MersenneTwister(47)
        uf = UnweightedParticleFilter(p, 1000, rng)
        ps = @inferred initialize_belief(uf, initialstate(p))
        a = @inferred rand(rng, actions(p))
        sp, o = @inferred @gen(:sp, :o)(p, rand(rng, ps), a, rng)
        bp = @inferred update(uf, ps, a, o)

        wp1 = @inferred collect(weighted_particles(ParticleCollection([1, 2])))
        wp2 = @inferred collect(weighted_particles(WeightedParticleBelief([1, 2], [1.0, 1.0])))
        @test wp1 == wp2
    end

    @testset "normal" begin
        pf = BootstrapFilter(ContinuousPOMDP(), 100)
        ps = @inferred initialize_belief(pf, Normal())
    end
end

struct TerminalPOMDP <: POMDP{Int,Int,Float64} end
POMDPs.isterminal(::TerminalPOMDP, s) = s == 1
POMDPs.observation(::TerminalPOMDP, a, sp) = Normal(sp)
POMDPs.transition(::TerminalPOMDP, s, a) = Deterministic(s + a)
@testset "pomdp terminal" begin
    pomdp = TerminalPOMDP()
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
    b = ParticleCollection([true for i = 1:100])

    # because baby is hungry, policy should feed (return true)
    @test action(policy, b) == true
    @test isapprox(value(policy, b), -29.4557)
end

# Note: we wrap each notebook in a module to avoid pollution of the global namespace.
# See also: https://github.com/JuliaLang/julia/issues/40189#issuecomment-871250226
cd("../notebooks/") do
    @testset "data series" begin
        @eval Module() begin
            Base.include(@__MODULE__, "../notebooks/Filtering-a-Trajectory-or-Data-Series.jl")
        end
    end

    @testset "feedback" begin
        @eval Module() begin
            Base.include(@__MODULE__, "../notebooks/Using-a-Particle-Filter-for-Feedback-Control.jl")
        end
    end

    @testset "pomdps" begin
        @eval Module() begin
            Base.include(@__MODULE__, "../notebooks/Using-a-Particle-Filter-with-POMDPs-jl.jl")
        end
    end
end
