### Resample Interface ###
"""
    resample(resampler, bp::AbstractParticleBelief, rng::AbstractRNG)

Sample a new ParticleCollection from `bp`.

Generic domain-independent resamplers should implement this version.

    resample(resampler, bp::WeightedParticleBelief, predict_model, reweight_model, b, a, o, rng)

Sample a new particle collection from bp with additional information from the arguments to the update function.

This version defaults to `resample(resampler, bp, rng)`. Domain-specific resamplers that wish to add noise to particles, etc. should implement this version.
"""
function resample end

resample(resampler, bp::WeightedParticleBelief, pm, rm, b, a, o, rng) = resample(resampler, bp, rng)

function resample(resampler, bp::WeightedParticleBelief, pm::Union{POMDP,MDP}, rm, b, a, o, rng)
    if weight_sum(bp) == 0.0 && all(isterminal(pm, s) for s in particles(b))
        error("Particle filter update error: all states in the particle collection were terminal.")
    end
    resample(resampler, bp, rng)
end

### Resamplers ###

"""
    ImportanceResampler(n)

Simple resampler. Uses alias sampling to attain O(n log(n)) performance with uncorrelated samples.
"""
struct ImportanceResampler
    n::Int
end

function resample(r::ImportanceResampler, b::AbstractParticleBelief{S}, rng::AbstractRNG) where {S}
    ps = Array{S}(undef, r.n)
    if weight_sum(b) <= 0
        warn("Invalid weights in particle filter: weight_sum = $(weight_sum(b))")
    end
    #XXX this may break if StatsBase changes
    StatsBase.alias_sample!(rng, particles(b), Weights(weights(b), weight_sum(b)), ps)
    return ParticleCollection(ps)
end

"""
    LowVarianceResampler(n)

Low variance sampling algorithm on page 110 of Probabilistic Robotics by Thrun Burgard and Fox. O(n) runtime, correlated samples, but produces a useful low-variance set.
"""
struct LowVarianceResampler
    n::Int
end

function resample(re::LowVarianceResampler, b::AbstractParticleBelief{S}, rng::AbstractRNG) where {S}
#@show "resample triggered alright"
    ps = Array{S}(undef, re.n)
    r = rand(rng)*weight_sum(b)/re.n
    c = weight(b,1) # weight of the first particle in the belief set
    i = 1
    U = r
    for m in 1:re.n # Loop over all the particles
        while U > c
            i += 1
            c += weight(b, i)
        end
        U += weight_sum(b)/re.n
        ps[m] = particles(b)[i]
    end
#@show ps
    return ParticleCollection(ps)
end

function resample(re::LowVarianceResampler, b::ParticleCollection{S}, rng::AbstractRNG) where {S}
    r = rand(rng)*n_particles(b)/re.n
    chunk = n_particles(b)/re.n
    inds = ceil.(Int, chunk*(0:re.n-1).+r)
    ps = particles(b)[inds]
    return ParticleCollection(ps)
end

n_init_samples(r::Union{LowVarianceResampler, ImportanceResampler}) = r.n

resample(f::Function, d::Any, rng::AbstractRNG) = f(d, rng)



"""
    CEMResampler(n)

Resample using the Cross Entropy Method
"""
struct CEMResampler
    n::Int
end
	# RpB: Function to convert matrix to array of arrays
# Call on the transpose of the input matrix
function slicematrix(A::AbstractMatrix)
    return [A[i, :] for i in 1:size(A,1)]
end

function resample(re::CEMResampler, b::AbstractParticleBelief{S}, rng::AbstractRNG) where {S}
#@show "cem resampple triggered alright"
	#print("\nStart of resampling\n")
	#print_particles(ParticleCollection(particles(b)))	
	sortedidx = sortperm(b.weights,rev=true)
	#@show sortedidx
	numtop = Int(0.2*re.n) # Top 20% of the number of particles to be selected as elite
	best_particles = b.particles[sortedidx[1:numtop]]
		#XXX: Printing things
		#print("After selecting the best particles \n")
		#@show length(best_particles)

		#print_particles(ParticleCollection(best_particles))	
	
	temp = hcat(best_particles...)'
	best_particles = temp'

	try
		p_distb = fit(MvNormal,best_particles)
		new_p_mat = rand(p_distb,re.n)
		new_p_array = slicematrix(new_p_mat')
			#XXX Printing things
			#print("\nFitted distb: $(p_distb)\n")		
			#print("\n after sampling from fitted distribution\n")
			#print_particles(ParticleCollection(new_p_array))
		return ParticleCollection(new_p_array)
	catch
		print("\n posdef exception was thrown\n")		
		return ParticleCollection(b.particles)
	end
end

#XXX: Move this particle printing function to a more apt file as comapred to resample.jl
function print_particles(b::ParticleCollection)
	for p in particles(b)
		print("\n$(p)")
	end
	return nothing
end
