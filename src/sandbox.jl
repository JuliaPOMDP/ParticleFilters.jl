# Sandbox for circling the origin dynamical system

using ParticleFilters
using Distributions
using StaticArrays
using LinearAlgebra
using Random
using Plots
using Reel

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

	N = 1000  # Rpb: Was 1000 before

	filter_sir = SIRParticleFilter(model, N) # This was originally present
	filter_cem = CEMParticleFilter(model, N) # This is the cem filter

	b = ParticleCollection([4.0*rand(4).-2.0 for i in 1:N])

	x = [0.0, 1.0, 1.0, 0.0]

	plots = []
	for i in 1:2    #RpB: was 100 before
	    print(".")
	    m = mean(b) # b is an array of particles. Each element in b is a 4 element tuple
	    u = [-m[1], -m[2]] # Control law - try to orbit the origin
	    x = f(x, u, rng)
	    y = h(x, rng)
	    b = update(filter_sir, b, u, y)

		# RpB: This is the update_cem
		b_cem = update(filter_cem,b,u,y)

	    plt = scatter([p[1] for p in particles(b)], [p[2] for p in particles(b)], 
		color=:black, markersize=2.0, label="",markershape=:diamond)
	    scatter!(plt, [x[1]], [x[2]], color=:blue, xlim=(-5,5), ylim=(-5,5), label="")
	    
		# RpB: Testing adding another group of particles
	    scatter!([p[1] for p in particles(b_cem)], [p[2] for p in particles(b_cem)], 
		color=:red, markersize=2.0, label="",markershape=:cross)
	    push!(plots, plt)
	end
	return plots
end # End of the runexp function

function write_particles_gif(plots)
@show "Making gif"
	frames = Frames(MIME("image/png"), fps=10)
	for plt in plots
	    print(".")
	    push!(frames, plt)
	end
	write("output.gif", frames)
	return nothing
end # End of the reel gif writing function

@show "Sandbox says: Calling runexp"
plots = runexp()

@show length(plots)

makegif = false
if makegif write_particles_gif(plots) end
