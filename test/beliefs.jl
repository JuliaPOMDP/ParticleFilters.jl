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
        @test mean(b) ≈ 10
        @test cov(b) ≈ [8/3]

        b = ParticleCollection(p2d)
        @inferred mean(b)
        @test mean(b) ≈ [10, 10]
        @test cov(b) ≈ fill(8/3, 2, 2)
        @test var(b) ≈ fill(8/3, 2)
    end

    @testset "weighted" begin
        b = WeightedParticleBelief(p, w)
        @inferred mean(b)
        @test mean(b) ≈ 9
        cov(b)

        b = WeightedParticleBelief(p2d, w)
        # @inferred mean(b)  # not type stable
        @test mean(b) ≈ [9, 9]
        cov(b)
    end
end