using ParticleFilters
using Distributions
using StaticArrays
using LinearAlgebra
using Random
using Plots

function runexp()
	rng = Random.GLOBAL_RNG

	dt = 0.1 # time step

	A = [1.0 0.0 dt  0.0;
		   0.0 1.0 0.0 dt ;
		   0.0 0.0 1.0 0.0;
		   0.0 0.0 0.0 1.0]

	B = [0.5*dt^2 0.0     ;
		   0.0      0.5*dt^2;
		   dt       0.0     ;
		   0.0      dt      ]

	W = Matrix(0.01*Diagonal{Float64}(I, 4)) # Process noise covariance
	V = Matrix(Diagonal{Float64}(I, 2)) # Measurement noise covariance

	f(x, u, rng) = A*x + B*u + rand(rng, MvNormal(W))

	h(x, rng) = rand(rng, MvNormal(x[1:2], V)) #Generates an observation
	g(x0, u, x, y) = pdf(MvNormal(x[1:2], V), y) #Creates likelihood

	model = ParticleFilterModel{Vector{Float64}}(f, g)

	N = 10

	filter = SIRParticleFilter(model, N)

	b = ParticleCollection([4.0*rand(4).-2.0 for i in 1:N])

	x = [0.0, 1.0, 1.0, 0.0]

	plots = []
	for i in 1:2    #RpB: was 100 before
	    print(".")
	    m = mean(b) # b is an array of particles. Each element in b is a 4 element tuple
	    u = [-m[1], -m[2]] # Control law - try to orbit the origin
	    x = f(x, u, rng)
	    y = h(x, rng)
	    b = update(filter, b, u, y)

	    plt = scatter([p[1] for p in particles(b)], [p[2] for p in particles(b)], 
		color=:black, markersize=0.1, label="")
	    scatter!(plt, [x[1]], [x[2]], color=:blue, xlim=(-5,5), ylim=(-5,5), label="")
	    push!(plots, plt)
	end
	return plots
end
@show "Calling runexp"
plots = runexp()

@show length(plots)
