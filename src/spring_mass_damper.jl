# Damped spring mass oscillator as another case study

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

	f(x,rng) = (Matrix(1.0*Diagonal(I,2)) + dt*A)*x

	# Initial state
	x = [1.0, 0.0]
	sigma_0 = [0.1 0;
		   0  0.1]
	
	positions = []
	plots = []
	# Let's first run the system and see how it behaves
	for i in 1:100
		x = f(x,rng)

		plt = scatter([x[1]],[2.0],xlim=(-5,5), ylim=(-5,5))
		push!(positions,x[1])
		push!(plots,plt)
	end
	return positions,plots
end

function make_gif(plots,filename)
display("Making gif")
	frames = Frames(MIME("image/png"), fps=5)
	for plt in plots
	    push!(frames, plt)
	end
	write(filename, frames)
	return nothing
end # End of the reel gif writing function

display("Running the spring mass damper system")
positions,plots = run_exp()
plot(positions)
savefig("springmassdamper_RestStart.png")
gifit = true
if gifit make_gif(plots,"springmassdamper_RestStart.mp4") end
