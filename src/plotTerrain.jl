# Script to plot the mountains from the fjord example
# Just a rudimentary for now. Will need to fill area under the curve

using Plots


# Function to plot the ground
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
savefig("terrain.png")
