using ParticleFilters
using Test
using Statistics

p = [8, 10, 12]
# particles in 2D state space
p2d = [
    [8, 8],
    [10, 10],
    [12, 12],
]
w = [4.0, 1.0, 1.0]

@testset "beliefs" begin

    @testset "unweighted" begin
        b = ParticleCollection(p)
        @inferred mean(b)
        @inferred cov(b)
        @test mean(b) ≈ 10
        @test cov(b) ≈ 8/3
        @test var(b) ≈ 8/3
        @test @inferred(rand(b)) isa eltype(p)
        @test rand(b) in p
        @test all(s in p for s in rand(b, 2))

        b = ParticleCollection(p2d)
        @inferred mean(b)
        @inferred cov(b)
        @test mean(b) ≈ [10, 10]
        @test cov(b) ≈ fill(8/3, 2, 2)
        @test var(b) ≈ fill(8/3, 2)
        @test @inferred(rand(b)) isa eltype(p2d)
        @test rand(b) in p2d
        @test all(s in p2d for s in rand(b, 2))
    end

    @testset "weighted" begin
        true_cov = cov([8, 8, 8, 8, 10, 12], corrected=false)
        b = WeightedParticleBelief(p, w)
        @inferred mean(b)
        @inferred cov(b)
        @test mean(b) ≈ 9
        @test cov(b) ≈ true_cov
        @test var(b) ≈ true_cov
        @test @inferred(rand(b)) isa eltype(p)
        @test rand(b) in p
        @test all(s in p for s in rand(b, 2))

        b = WeightedParticleBelief(p2d, w)
        @inferred mean(b)
        @inferred cov(b)
        @test mean(b) ≈ [9, 9]
        @test cov(b) ≈ fill(true_cov, 2, 2)
        @test var(b) ≈ fill(true_cov, 2)
        @test @inferred(rand(b)) isa eltype(p2d)
        @test rand(b) in p2d
        @test all(s in p2d for s in rand(b, 2))
    end
end
