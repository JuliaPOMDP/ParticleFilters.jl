import StatsBase

# Copied from StatsBase
function alias_sample!(rng::AbstractRNG, a::AbstractArray, weights::AbstractArray, weight_sum::Float64, x::AbstractArray)
    n = length(a)
    length(weights) == n || throw(DimensionMismatch("Inconsistent lengths."))

    # create alias table
    ap = Array(Float64, n)
    alias = Array(Int, n)
    StatsBase.make_alias_table!(weights, weight_sum, ap, alias)

    # sampling
    js = rand(rng, 1:n, length(x))
    for i = 1:length(x)
        j = js[i]
        x[i] = rand(rng) < ap[j] ? a[j] : a[alias[j]]
    end
    return x
end
