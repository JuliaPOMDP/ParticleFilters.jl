# Script to plot the mountains from the fjord example
# Just a rudimentary for now. Will need to fill area under the curve

using Plots

# Function to plot the aircraft
function plot_aircraft(xpos,ypos)
	X = xpos - 0.6 .+ [-1,     -0.1,   -0.09,    0.3,  0.7, 0.8, 0.7, 0.3, -0.09,  -0.1, -1];
	Y = ypos .+ [-0.05, -0.05, -0.4, -0.05, -0.05,0, 0.05, 0.05, 0.4, 0.05, 0.05];
	return X,Y
end


# Function to create the terrain by calculating y for input x
function ground(x)
       return (x>=10).*((1-(x-10)/30).*sin(x-10)+((x-10)/30).*sin(1.5*(x-10))+
	0.2.*(x-10).*(x<=20)+2*(x>20))+(x<=-10).*((1-(-x-10)/30).*sin(-x-10)+
	((-x-10)/30).*sin(1.5*(-x-10))+0.2.*(-x-10).*(x>=-20)+2*(x<-20))
end

#----------cool trick to make function work with arrays when written for scalars---
#julia> map.(ground,[11,12])
#2-element Array{Float64,1}:
# 1.0466717848677685
# 1.258085598907961 
#------------------------------------------------------------

# Sea not really needed since its flat 0 and plot of mountain automatically takes care
plotVectorSea = collect(-10:0.01:10)

# Here are the mountains
mt1 = collect(-40:0.01:-10.01)
mt2 = collect(10.01:0.01:40)
plotVectorMountains = vcat(mt1,mt2)

# Call the ground function on the x locations that are deemed as mountain above
Mountains = map.(ground,plotVectorMountains)

plot(plotVectorMountains,Mountains)
#savefig("terrain.png")

plane_X, plane_Y = plot_aircraft(0,4)
plot!(plane_X,plane_Y)

N = 100 # Number of particles
particles = [80*rand(1)[1]-40 for i in 1:N]
scatter!(particles,4*ones(N))
savefig("terrain+ac+particles.png")
