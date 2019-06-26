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
function plot_terrain_ac(xpos,ypos)
#@show "terrain plotter being called"
	X = xpos[1] - 0.6 .+ [-1,-0.1,-0.09,0.3,0.7,0.8,0.7, 0.3, -0.09,  -0.1, -1];
	Y = ypos .+ [-0.05, -0.05, -0.4, -0.05, -0.05,0, 0.05, 0.05, 0.4, 0.05, 0.05];

	# Here are the mountains
	mt1 = collect(-40:0.01:-10.01)
	mt2 = collect(10.01:0.01:40)
	plotVectorMountains = vcat(mt1,mt2)

	# Call the ground function on the x locations that are deemed as mountain above
	Mountains = map.(ground,plotVectorMountains)

	plt = plot(plotVectorMountains,Mountains,label="Terrain") # Plot the terrain
	plot!(X,Y,label="Aircraft") # Plot the aircraft
	
	return plt
end

"""
	write_particles_gif(plots)
Take input array of plots and convert to gif animation
"""
function write_particles_gif(plots)
	print("\n Making gif\n")
	frames = Frames(MIME("image/png"), fps=5)
	for plt in plots
	    push!(frames, plt)
	end
	write("../img/Fjord/26June/fjord.mp4", frames)
	return nothing
end # End of the reel gif writing function


function runexp()
	rng = Random.GLOBAL_RNG

	dt = 0.1 # time step

	ypos = 4 # Height of the aircraft stays constant
	meas_stdev = 2
	A = [1]
	B = [0]
	f(x, u, rng) = x #+ [1.0] # Investigating fixed state
	h(x, rng) = rand(rng, Normal(ypos-ground(x[1]), meas_stdev)) #Generates an observation
	g(x0, u, x, y) = pdf(Normal(ypos - ground(x[1]), meas_stdev), y) #Creates likelihood

	model = ParticleFilterModel{Vector{Float64}}(f, g)

	N = 50  # Rpb: Was 1000 before

	filter_sir = SIRParticleFilter(model, N) # This was originally present
	filter_cem = CEMParticleFilter(model, N) # This is the cem filter

	b_sir = ParticleCollection([[80.0*rand(1)[1]-40.0] for i in 1:N])
	b_cem = b_sir

	x = [-25.0]

	plots = []
	
	plt = plot_terrain_ac(x,ypos)
	scatter!([p[1] for p in particles(b_sir)],[ypos for p in particles(b_sir)],label="SIR",xlim=(-30,30),color=:blue)

	scatter!([p[1] for p in particles(b_cem)],[ypos for p in particles(b_cem)],label="CEM",xlim=(-30,30),color=:green)

#	scatter!(particles(b_sir),4*ones(length(particles(b_sir))),label="SIR",xlim=(-30,30),color=:blue)
# 	scatter!(particles(b_cem),4*ones(length(particles(b_cem))),label="CEM",xlim=(-30,30),color=:green)
	push!(plots,plt)
	for i in 1:50    #RpB: was 100 before
		#print(".")
		u = 1
		x = f(x, u, rng)
		y = h(x, rng)
		b_sir = update(filter_sir, b_sir, u, y)

		# RpB: This is the update_cem
		b_cem = update(filter_cem,b_cem,u,y)

		plt = plot_terrain_ac(x,ypos)

	scatter!([p[1] for p in particles(b_sir)],[ypos for p in particles(b_sir)],label="SIR",xlim=(-30,30),color=:blue)

	scatter!([p[1] for p in particles(b_cem)],[ypos for p in particles(b_cem)],label="CEM",xlim=(-30,30),color=:green)

#		scatter!(particles(b_sir),4*ones(length(particles(b_sir))),label="SIR",xlim=(-30,30),color=:blue)
#		scatter!(particles(b_cem),4*ones(length(particles(b_cem))),label="CEM",xlim=(-30,30),color=:green)
	
		push!(plots, plt)
	end
	return plots
end # End of the runexp function


@show "Sandbox says: Calling runexp"
plots = runexp()

@show length(plots)

makegif = true
if makegif write_particles_gif(plots) end
