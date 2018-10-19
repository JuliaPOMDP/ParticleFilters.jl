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
