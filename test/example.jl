using ParticleFilters
using Distributions
using StaticArrays
using LinearAlgebra
using Random

# 2D Double Integrator
# state is [x, y, xdot, ydot];

const dt = 0.1
const A = [1.0 0.0 dt  0.0;
           0.0 1.0 0.0 dt ;
           0.0 0.0 1.0 0.0;
           0.0 0.0 0.0 1.0]

const B = [0.5*dt^2 0.0     ;
           0.0      0.5*dt^2;
           dt       0.0     ;
           0.0      dt      ]

const W = Matrix(0.001*Diagonal{Float64}(I, 4)) # Process noise covariance
const V = Matrix(Diagonal{Float64}(I, 2)) # Measurement noise covariance

f(x, u, rng) = A*x + B*u + rand(rng, MvNormal(W))
g(x0, u, x, y) = pdf(MvNormal(x[1:2], V), y)
model = ParticleFilterModel{Vector{Float64}}(f, g)

h(x, rng) = rand(rng, MvNormal(x[1:2], V))

@testset "example" begin
    N = 1000
    filter = BootstrapFilter(model, N)
    Random.seed!(1)
    rng = Random.GLOBAL_RNG
    b = ParticleCollection([4.0*rand(4).-2.0 for i in 1:N])
    x = [0.0, 1.0, 1.0, 0.0]
    for i in 1:100
        print(".")
        m = mean(b)
        u = [-m[1], -m[2]] # try to orbit the origin
        x = f(x, u, rng)
        y = h(x, rng)
        b = update(filter, b, u, y)

        # scatter([p[1] for p in particles(b)], [p[2] for p in particles(b)], color=:black, markersize=0.1, label="")
        # scatter!([s[1]], [s[2]], color=:blue, xlim=(-5,5), ylim=(-5,5), title=t, label="")
    end
    # write("particles.gif", film)
end
