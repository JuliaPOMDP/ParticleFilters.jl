# Fjord

using ParticleFilters
using Distributions
using StaticArrays
using LinearAlgebra
using Random
using Plots
using Reel

"""
	ground(x)
Returns the height of the ground from sea level at input x location
"""
function ground(x)
       return (x>=10).*((1-(x-10)/30).*sin(x-10)+((x-10)/30).*sin(1.5*(x-10))+
	0.2.*(x-10).*(x<=20)+2*(x>20))+(x<=-10).*((1-(-x-10)/30).*sin(-x-10)+
	((-x-10)/30).*sin(1.5*(-x-10))+0.2.*(-x-10).*(x>=-20)+2*(x<-20))
end

"""
Plot the terrain, aircraft and particles
# - --------------Experimentation
@show "Testing terrain making function in fjord.jl"
N = 100 # Number of particles
particles = [80*rand(1)[1]-40 for i in 1:N]
plt = plot_terrain_ac_particles(0,4,particles)
savefig(plt,"test_terrain.png")
"""
function plot_terrain_ac_particles(xpos,ypos,particles)
#@show "terrain plotter being called"
	X = xpos[1] - 0.6 .+ [-1,     -0.1,   -0.09,    0.3,  0.7, 0.8, 0.7, 0.3, -0.09,  -0.1, -1];
	Y = ypos .+ [-0.05, -0.05, -0.4, -0.05, -0.05,0, 0.05, 0.05, 0.4, 0.05, 0.05];

	# Here are the mountains
	mt1 = collect(-40:0.01:-10.01)
	mt2 = collect(10.01:0.01:40)
	plotVectorMountains = vcat(mt1,mt2)

	# Call the ground function on the x locations that are deemed as mountain above
	Mountains = map.(ground,plotVectorMountains)

	plt = plot(plotVectorMountains,Mountains,leg=false) # Plot the terrain
	plot!(X,Y,leg=false) # Plot the aircraft
	scatter!(particles,4*ones(length(particles)),leg=false)
	return plt
end

"""
	write_particles_gif(plots)
Take input array of plots and convert to gif animation
"""
function write_particles_gif(plots)
@show "Making gif"
	frames = Frames(MIME("image/png"), fps=5)
	for plt in plots
	    print(".")
	    push!(frames, plt)
	end
	write("fjord.gif", frames)
	return nothing
end # End of the reel gif writing function


function runexp()
	rng = Random.GLOBAL_RNG

	dt = 0.1 # time step

	ypos = 4 # Height of the aircraft stays constant
	meas_stdev = 0.1
	A = [1]
	B = [0]
	f(x, u, rng) = x #+ [1.0] # Investigating fixed state
	h(x, rng) = rand(rng, Normal(ypos-ground(x[1]), meas_stdev)) #Generates an observation
	g(x0, u, x, y) = pdf(Normal(ypos - ground(x[1]), meas_stdev), y) #Creates likelihood

	model = ParticleFilterModel{Vector{Float64}}(f, g)

	N = 1000  # Rpb: Was 1000 before

	filter_sir = SIRParticleFilter(model, N) # This was originally present
	filter_cem = CEMParticleFilter(model, N) # This is the cem filter

	b = ParticleCollection([[80.0*rand(1)[1]-40.0] for i in 1:N])

	x = [-25.0]

	plots = []
plt = plot_terrain_ac_particles(x,ypos,particles(b))
push!(plots,plt)
	for i in 1:50    #RpB: was 100 before
	    print(".")
	    u = 1
	    x = f(x, u, rng)
#@show x
	    y = h(x, rng)
#@show y
	    b = update(filter_cem, b, u, y)

#@show particles(b)
		# RpB: This is the update_cem
		#b_cem = update(filter_cem,b,u,y)
#@show particles(b_cem)
	    plt = plot_terrain_ac_particles(x,ypos,particles(b))
	    push!(plots, plt)
	end
	return plots
end # End of the runexp function



@show "Sandbox says: Calling runexp"
plots = runexp()

@show length(plots)

makegif = true
if makegif write_particles_gif(plots) end
