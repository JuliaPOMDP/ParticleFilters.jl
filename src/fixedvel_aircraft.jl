# Velocity is fixed but cant be observed. Position changes but can be noisily observed
using ParticleFilters
using Distributions
using StaticArrays
using LinearAlgebra
using Random
using Plots
using Reel
using Statistics

"""
Q = V measurement noise covariance
R = W process noise covariance
C = I because observation h is basically true state corrupted by noise
"""
function kalman_filter(mu,sigma,u,z,A,B,C,R,Q)
	mu_bar = A*mu + B*u
	sigma_bar = A*sigma*A' + R

	K = sigma_bar*C'*(inv(C*sigma_bar*C'+Q))

	mu_new = mu_bar+K*(z-C*mu_bar)
	sigma_new = (I-K*C)*sigma_bar
	return mu_new,sigma_new
end

function run_kf(mu_0,sig_0,num_iter)
	display("Running kalman filter for $(num_iter) iterations")
	rng = Random.GLOBAL_RNG
	dt = 0.1
	A = [1.0 0.0 dt  0.0;
	     0.0 1.0 0.0 dt ;
	     0.0 0.0 1.0 0.0;
	     0.0 0.0 0.0 1.0]

	B = [0.0 0.0;
	     0.0 0.0;
             0.0  0.0;
             0.0 0.0]

	# Measurement matrix i.e. y = Cx + N(0,V)
	C = [1.0 0.0 0.0 0.0; 
	     0.0 1.0 0.0 0.0]

	W = Matrix(0.001*Diagonal{Float64}(I, 4)) # Process noise covariance
	V = Matrix(5.0*Diagonal{Float64}(I, 2)) # Measurement noise covariance

	f(x, u, rng) = A*x + rand(rng, MvNormal(W))
	h(x, rng) = rand(rng, MvNormal(x[1:2], V)) #Generates an observation	
	mu = mu_0
	sigma = sig_0
	x = [1.,1.,1.,1.]
	u = [-1.0,-1.0] # Just a dummy but still needs to be correct size to multiply B

	plots = []

	for i in 1:num_iter
		x = f(x, u, rng)
		z = h(x, rng)
		mu,sigma = kalman_filter(mu,sigma,u,z,A,B,C,W,V)
		
		plt = scatter([mu[1]], [mu[2]], color=:black, markersize=2.0, label="kf",markershape=:diamond)
		scatter!(plt, [x[1]], [x[2]], color=:blue, xlim=(-5,25), ylim=(-5,25), 
			label = "true")
		push!(plots,plt)
	end
	return plots
end

function runexp(num_particles)
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
	
	W = Matrix(0.001*Diagonal{Float64}(I, 4)) # Process noise covariance
	V = Matrix(5.0*Diagonal{Float64}(I, 2)) # Measurement noise covariance

	f(x, u, rng) = A*x + rand(rng, MvNormal(W))

	h(x, rng) = rand(rng, MvNormal(x[1:2], V)) #Generates an observation
	g(x0, u, x, y) = pdf(MvNormal(x[1:2], V), y) #Creates likelihood

	model = ParticleFilterModel{Vector{Float64}}(f, g)

	N = num_particles

	filter_sir = SIRParticleFilter(model, N) # Vanilla particle filter
	filter_cem = CEMParticleFilter(model, N) # CEM filter

	b = ParticleCollection([4.0*rand(4).-2.0 for i in 1:N])

	x = [1.0, 1.0, 1.0, 1.0]

	plots = []

	num_iter = 100
	rmse = zeros(num_iter,2)
	rmse_elites = zeros(num_iter,2)

	for i in 1:num_iter    #RpB: was 100 before
		#@show i
		m = mean(b) # b is an array of particles. Each element in b is a 4 element tuple
		u = [-m[1], -m[2]] # Control law - try to orbit the origin	
		x = f(x, u, rng)
		y = h(x, rng)
		b = update(filter_sir, b, u, y)
		#display("SIR update done")
		
		b_cem = update(filter_cem,b,u,y)
		#@show "cem update done"
		plt = scatter([p[1] for p in particles(b)], [p[2] for p in particles(b)], color=:black, markersize=2.0, label="sir",markershape=:diamond)
		scatter!(plt, [x[1]], [x[2]], color=:blue, xlim=(-5,15), ylim=(-5,15), 
			label = "true")
	    
		# RpB: Testing adding another group of particles
		scatter!([p[1] for p in particles(b_cem)], [p[2] for p in particles(b_cem)], color=:red, markersize=2.0, label="cem",markershape=:cross)
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
	#plot(hcat(rmse,rmse_elites),labels=["sir","cem","sir_el","cem_el"])
	#savefig("rmse.png")
	return plots,rmse
	
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

function write_particles_gif(plots,filename)
@show "Making gif"
	frames = Frames(MIME("image/png"), fps=10)
	for plt in plots
	    push!(frames, plt)
	end
	write(filename, frames)
	return nothing
end # End of the reel gif writing function

# Run the filtering multiple times and average the results from all the experiments
# Third dimension of the `data` data structure denotes experiment number
# Each exp returns a table with timeslices in rows and rmse_sir and rmse_cem
# in columns. Each new table is stacked on top of table from previous experiment
function run_many_exps(;num_exp,num_particles)	
	display("Running $(num_exp) experiments with $(num_particles) particles")	
	data = zeros(100,2,num_exp)
	for i in 1:num_exp
		if i%20 == 0.
			@show i
		end		
		plt,data[:,:,i] = runexp(num_particles)
	end
	rmse_avg = mean(data,dims=3)[:,:,1] #Extract 100x2 array from 100x2x1 array
	plot(rmse_avg,labels=["sir","cem"])
	savefig("rmse_avg_numexps_$(num_exp)_numparticles_$(num_particles)_highCov.png")
	return nothing
end

run1exp = false
runmanyexp = false
runkf = true
if run1exp
	# Single experiment and make associated video	
	display("Running a single experiment and making associated video")
	plots, rmse = runexp(1000)
	@show length(plots) # Should be equal to the number of iterations of the particle filter
	makegif = true
	if makegif write_particles_gif(plots,"100particles_HighMeasCov.mp4") end
end
if runmanyexp
	# Mulitple experiments to make average rmse plot
	run_many_exps(num_exp = 100, num_particles = 100)
end
if runkf
	mu_0 = [1.,1.,1.,1.]
	sig_0 = Matrix(1.0*Diagonal{Float64}(I, 4))
	num_iter = 500
	
	plot_kf = run_kf(mu_0,sig_0,num_iter)
	makegif = true
	if makegif write_particles_gif(plot_kf,"KalmanFilter_num_iter_$(num_iter).mp4") end
end
