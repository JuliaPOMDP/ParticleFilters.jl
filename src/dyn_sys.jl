# Sandbox for circling the origin dynamical system

using ParticleFilters
using Distributions
using StaticArrays
using LinearAlgebra
using Random
using Plots
using Reel
using Statistics

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

	num_iter = 100
	rmse = zeros(num_iter,2)
	rmse_elites = zeros(num_iter,2)

	for i in 1:num_iter    #RpB: was 100 before
	    #print(".")
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

	    # Plot the rmse value for the current iteration of particles
		# Vanilla rmse
 	    rmse_sir=calc_rmse(b,x)
	    rmse_sir_elites = calc_rmse_elites(b,x)
	    rmse_cem=calc_rmse(b_cem,x)
	    rmse[i,1] = rmse_sir
	    rmse[i,2] = rmse_cem

		# Elites calculation
	    rmse_sir_elites = calc_rmse_elites(b,x)
	    rmse_cem_elites = calc_rmse_elites(b_cem,x)
	    rmse_elites[i,1] = rmse_sir_elites
	    rmse_elites[i,2] = rmse_cem_elites
	end

	#plot(rmse,labels=["sir","cem"])
	plot(hcat(rmse,rmse_elites),labels=["sir","cem","sir_el","cem_el"])
	savefig("rmse.png")
	return plots
	
end # End of the runexp function

# Find the mean particle from a collection
function find_mean_particle(b::ParticleCollection)
	return mean(b.particles)
end

"""
	calc_rmse_old(b:ParticleCollection,x)
# Arguments
- x: True state - 4 element array. The first two elems (i.e. x,y coord) are used
for norm computation
- b: Collection of particles
"""
function calc_rmse_old(b::ParticleCollection,x)
	#Extract particles from belief
	particles = b.particles
	n = n_particles(b)	

	sum_sq_error = 0
	# Loop over all the particles and store the square norm sum
	for i in 1:n
		p = particles[i][1:2]
		sum_sq_error = sum_sq_error + norm(p-x[1:2])*norm(p-x[1:2])
	end
	return sqrt(sum_sq_error/n)
end

function calc_rmse(b::ParticleCollection,x)
	norm_vec = calc_norm_squared(b,x)
	return sqrt(mean(norm_vec))
end

"""
Returns an array with each elem being norm squared
from ground truth to particle
"""
function calc_norm_squared(b::ParticleCollection,x)
	particles = b.particles
	n = n_particles(b)	

	norm_squared = zeros(n)
	for i in 1:n
		p = particles[i][1:2]
		norm_squared[i] = norm(p-x[1:2])*norm(p-x[1:2])
	end
	return norm_squared
end

function calc_rmse_elites(b::ParticleCollection,x)
	particles = b.particles
	n = n_particles(b)
	n_elites = Int(0.2*n)
	norm_vec = calc_norm_squared(b,x)
	elite_particles = particles[sortperm(norm_vec)[1:n_elites]]
	return calc_rmse(ParticleCollection(elite_particles),x)
end

function write_particles_gif(plots)
@show "Making gif"
	frames = Frames(MIME("image/png"), fps=10)
	for plt in plots
	    push!(frames, plt)
	end
	write("output.mp4", frames)
	return nothing
end # End of the reel gif writing function

@show "Sandbox says: Calling runexp"
plots = runexp()

@show length(plots)

makegif = true
if makegif write_particles_gif(plots) end
