struct BasicPredictor{F<:Function} <: Function
    dynamics::F
end

(p::BasicPredictor)(b, u, y, rng) = map(x -> p.dynamics(x, u, rng), particles(b))

struct BasicReweighter{G<:Function} <: Function
    reweight::G
end

function (r::BasicReweighter)(b, u, ps, y)
    map(1:length(ps)) do i
        x1 = particle(b, i)
        x2 = ps[i]
        r.reweight(x1, u, x2, y)
    end
end
