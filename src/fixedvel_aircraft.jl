# Velocity is fixed but cant be observed. Position changes but can be noisily observed
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

	B = [0.0 0.0;
	     0.0 0.0;
             0.0  0.0;
             0.0 0.0]

	W = Matrix(0.0*Diagonal{Float64}(I, 4)) # No noise i.e. stochastic
	V = Matrix(Diagonal{Float64}(I, 2)) # Measurement noise covariance

	f(x, u, rng) = A*x

	h(x, rng) = rand(rng, MvNormal(x[1:2], V)) #Generates an observation
	g(x0, u, x, y) = pdf(MvNormal(x[1:2], V), y) #Creates likelihood

	model = ParticleFilterModel{Vector{Float64}}(f, g)

	N = 1000

	filter_sir = SIRParticleFilter(model, N) # Vanilla particle filter
	filter_cem = CEMParticleFilter(model, N) # CEM filter

	b = ParticleCollection([4.0*rand(4).-2.0 for i in 1:N])

	x = [1.0, 1.0, 1.0, 1.0]

	plots = []

	num_iter = 10
	rmse = zeros(num_iter,2)
	rmse_elites = zeros(num_iter,2)

	for i in 1:num_iter    #RpB: was 100 before
		@show i
		m = mean(b) # b is an array of particles. Each element in b is a 4 element tuple
		
		#@show m		
		u = [-m[1], -m[2]] # Control law - try to orbit the origin
		@show x		
		x = f(x, u, rng)
		@show x
		y = h(x, rng)
		@show y
		b = update(filter_sir, b, u, y)
		@show "sir update done"
		
		b_cem = update(filter_cem,b,u,y)
		@show "cem update done"
		plt = scatter([p[1] for p in particles(b)], [p[2] for p in particles(b)], color=:black, markersize=2.0, label="",markershape=:diamond)
		scatter!(plt, [x[1]], [x[2]], color=:blue, xlim=(-5,5), ylim=(-5,5), label="")
	    
		# RpB: Testing adding another group of particles
		scatter!([p[1] for p in particles(b_cem)], [p[2] for p in particles(b_cem)], color=:red, markersize=2.0, label="",markershape=:cross)
		push!(plots, plt)

		
		# Plot the rmse value for the current iteration of particles
		# Vanilla rmse
 		rmse_sir=calc_rmse(b,x)
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

# Uses the norm squared calculation function to find the rmse
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

# Calc the rmse of the top 20% particles in the distribution
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

@show "Start experiement: noisy aircraft"
plots = runexp()

@show length(plots)

makegif = true
if makegif write_particles_gif(plots) end
