# Damped spring mass oscillator as another case study

# Idea: Plot true position, Kalman filter posterior mean, particle distribution, cem distribution

using ParticleFilters
using Distributions
using StaticArrays
using LinearAlgebra
using Random
using Plots
using Reel
using Statistics

function run_exp()
	rng = Random.GLOBAL_RNG
	dt = 0.1
	m = 10.
	k = 5.
	b = 3.
	A = [  0    1;
	    -k/m -b/m]

	f(x,u,rng) = (Matrix(1.0*Diagonal(I,2)) + dt*A)*x

	# Initial state
	x = [1.0, 0.0]
	sigma_0 = [0.1 0;
		   0  0.1]
	
	positions = []	# Store the location of the mass i.e. x location
	plots = []
	
		# Set up for kalman filter
	C = [1.0 0.0] # Measurement matrix y=Cx
	mu = [1.0 1.0]	# Mean of initial gaussian belief
	sigma = sigma_0	# Covariance of initial gaussian belief

		# Set up for particle filter and cem filter
	model = ParticleFilterModel{Vector{Float64}}(f, g)
	N = 100 # Number of particles

	filter_sir = SIRParticleFilter(model, N) # Vanilla particle filter
	filter_cem = CEMParticleFilter(model, N) # CEM filter

	b = ParticleCollection([1.0*rand(2) for i in 1:N]) # Each particle is 2 element array

		# Run iterations
	for i in 1:100
		u = [1.0, 1.0]	# Dummy variable as plays no role in state transition
		x = f(x,u,rng)	# Propagate state forward by 1 step
		y = h(x, rng)	# Generate a noisy observation of the state
		
			# Kalman filtering estimate
		mu,sigma = kalman_filter(mu,sigma,u,y,A,B,C,W,V)

			# Particle filtering estimate
		b = update(filter_sir, b, u, y)
			
			# Cross entropy filtering estimate
		b_cem = update(filter_cem,b,u,y)

		plt = scatter([x[1]],[2.0],color=:black,label="true",xlim=(-5,5), ylim=(-5,5))
		scatter!([mu[1]],[2.0],color=:blue,label="kf",xlim=(-5,5), ylim=(-5,5))
		scatter!([p[1] for p in particles(b)],[2.0],color=:cyan,
			label="sir",xlim=(-5,5), ylim=(-5,5))
		scatter!([p[1] for p in particles(b_cem)],[2.0],color=:magenta,
			label="cem",xlim=(-5,5), ylim=(-5,5))
		
		push!(positions,x[1])
		push!(plots,plt)
	end
	return positions,plots
end

"""
gif making function
"""
function make_gif(plots,filename)
display("Making gif")
	frames = Frames(MIME("image/png"), fps=5)
	for plt in plots
	    push!(frames, plt)
	end
	write(filename, frames)
	return nothing
end # End of the reel gif writing function

"""
Kalman filter function

# Arguments:
Q: Measurement noise covariance
R: Process noise covariance

# Understanding:
The Kalman filter is the `optimal estimator` in that it yields the least possible
mean value of sum of squared estimation error
"""
function kalman_filter(mu,sigma,u,z,A,B,C,R,Q)
	mu_bar = A*mu + B*u
	sigma_bar = A*sigma*A' + R

	K = sigma_bar*C'*(inv(C*sigma_bar*C'+Q))

	mu_new = mu_bar+K*(z-C*mu_bar)
	sigma_new = (I-K*C)*sigma_bar
	return mu_new,sigma_new
end

display("Running the spring mass damper system")
positions,plots = run_exp()
plot(positions)
savefig("springmassdamper_RestStart.png")
gifit = true
if gifit make_gif(plots,"springmassdamper_RestStart.mp4") end
