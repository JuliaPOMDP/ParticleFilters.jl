"""
    runfilter(fil, b0, us, ys)

Run the particle filter `fil` starting with belief `b0` with control sequence `us` and measurement sequence `ys`. Return the resulting sequence of particle collections.

This function is intended for post-processing pre-recorded data with a particle filter.

# Arguments
- `fil`: A particle filter (e.g. constructed with `BasicParticleFilter`)
- `b0`: The initial belief. Can be any distribution over initial states.
- `us`: A sequence of control inputs for the system.
- `ys`: A sequence of measurements (observations) received after each control input.

# Return value
A sequence of particle collections. This will not include `b0` and will be the same length as `us` and `ys`. Each particle collection in this sequence is the one after being updated with the corresponding measurement in `ys`.
"""
function runfilter(f::Updater, b0, us::AbstractVector, ys::AbstractVector)
    b = initialize_belief(f, b0)
    bs = Any[]
    @assert length(ys) >= length(us)
    for i in 1:length(us)
        b = update(f, b, us[i], ys[i])
        push!(bs, b)
    end
    return bs
end
