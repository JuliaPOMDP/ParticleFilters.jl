# Sandbox for lightdark system

using ParticleFilters
using Reel
using POMDPs
using POMDPModels
using POMDPSimulators
using POMDPPolicies
using Random
using Plots
using Reel

function runexp()
	pomdp = LightDark1D()
	N=1000
	up = SIRParticleFilter(pomdp, N)
	policy = FunctionPolicy(b->1)
	b0 = POMDPModels.LDNormalStateDist(-15.0, 5.0)
	hr = HistoryRecorder(max_steps=40)
	history = simulate(hr, pomdp, policy, up, b0)

	return history
end	# End of experiment runner

function write_gif_histogram(history)
@show making gif
	frames = Frames(MIME("image/png"), fps=4)
	for b in belief_hist(history)
	    ys = [s.y for s in particles(b)]
	    nbins = round(Int, (maximum(ys)-minimum(ys))*2)
	    push!(frames, histogram(ys,
		                    xlim=(-20,20),
		                    ylim=(0,1000),
		                    nbins=nbins,
		                    label="",
		                    title="Particle Histogram")
		                    
	    )
	end
	write("hist.gif", frames)
	return nothing
end	# End of gif making function

@show "Running light dark exp"
history = runexp()

makegif = false
if makegif write_gif_histogram(history) end
