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


function test_pdf(b)
    for p in particles(b)
        @test 0.0 <= pdf(b, p) <= 1.0
    end
    @test sum(pdf(b, s) for s in unique(particles(b))) ≈ 1.0
end

function test_interface!(b)
    @test n_particles(b) == length(particles(b))
    @test length(particles(b)) == length(weights(b))
    @test first(@inferred(weighted_particles(b))) isa Pair{eltype(particles(b)), eltype(weights(b))}
    @test weight_sum(b) ≈ sum(weights(b))
    @test weight(b, 1) == first(weights(b))
    @test weight(b, n_particles(b)) == last(weights(b))
    @test particle(b, 1) == first(particles(b))
    @test particle(b, n_particles(b)) == last(particles(b))
    @test @inferred(rand(b)) isa eltype(particles(b))
    @test rand(b) in particles(b)
    @test all(s in particles(b) for s in rand(b, 2))

    test_pdf(b)

    i = rand(1:n_particles(b))
    j = rand(1:n_particles(b))
    ip = particle(b, i)
    iw = weight(b, i)
    jp = particle(b, j)
    jw = weight(b, j)
    set_particle!(b, i, jp)
    set_weight!(b, i, jw)
    @test particle(b, i) == jp
    @test weight(b, i) == jw

    set_pair!(b, j, ip=>iw)
    @test particle(b, j) == ip
    @test weight(b, j) == iw

    test_pdf(b)

    original_length = n_particles(b)
    push_pair!(b, ip=>iw)
    @test particle(b, n_particles(b)) == ip
    @test weight(b, n_particles(b)) == iw
    @test n_particles(b) == original_length + 1

    test_pdf(b)
end

@testset "beliefs" begin

    @testset "unweighted" begin
        b = ParticleCollection(copy(p))
        @inferred mean(b)
        @inferred cov(b)
        @test mean(b) ≈ 10
        @test cov(b) ≈ 8/3
        @test var(b) ≈ 8/3
        test_interface!(b)

        b = ParticleCollection(copy(p2d))
        @inferred mean(b)
        @inferred cov(b)
        @test mean(b) ≈ [10, 10]
        @test cov(b) ≈ fill(8/3, 2, 2)
        @test var(b) ≈ fill(8/3, 2)
        test_interface!(b)
    end

    @testset "weighted" begin
        true_cov = cov([8, 8, 8, 8, 10, 12], corrected=false)
        b = WeightedParticleBelief(copy(p), copy(w))
        @inferred mean(b)
        @inferred cov(b)
        @test mean(b) ≈ 9
        @test cov(b) ≈ true_cov
        @test var(b) ≈ true_cov
        test_interface!(b)

        b = WeightedParticleBelief(copy(p2d), copy(w))
        @inferred mean(b)
        @inferred cov(b)
        @test mean(b) ≈ [9, 9]
        @test cov(b) ≈ fill(true_cov, 2, 2)
        @test var(b) ≈ fill(true_cov, 2)
        test_interface!(b)
    end
end
