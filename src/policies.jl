#=
Implementation specific to using ParticleBeliefs with AlphaVectorPolicy from POMDPToolbox
these are more efficient than converting the ParticleBelief to a DiscreteBelief
=#

"""
Given a particle belief, return the unnormalized utility function that weights each state value by the weight of
the corresponding particle
    unnormalized_util(p::AlphaVectorPolicy, b::AbstractParticleBelief)
"""
function unnormalized_util(p::AlphaVectorPolicy, b::AbstractParticleBelief)
    util = zeros(n_actions(p.pomdp))
    for (i, s) in enumerate(particles(b))
        j = stateindex(p.pomdp, s)
        util += weight(b, i)*getindex.(p.alphas, (j,))
    end
    return util
end

function action(p::AlphaVectorPolicy, b::AbstractParticleBelief)
    util = unnormalized_util(p, b)
    ihi = argmax(util)
    return p.action_map[ihi]
end

value(p::AlphaVectorPolicy, b::AbstractParticleBelief) = maximum(unnormalized_util(p, b))/weight_sum(b)
