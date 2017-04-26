@generated function obs_weight(p, s, a, sp, o)
    if implemented(obs_weight, Tuple{p, a, sp, o})
        return :(obs_weight(p, a, sp, o))
    elseif implemented(observation, Tuple{p, s, a, sp})
        return :(pdf(observation(p, s, a, sp), o))
    else
        return :(throw(MethodError(obs_weight, (p,s,a,sp,o))))
    end
end

@generated function obs_weight(p, a, sp, o)
    if implemented(obs_weight, Tuple{p, sp, o})
        return :(obs_weight(p, sp, o))
    elseif implemented(observation, Tuple{p, a, sp})
        return :(pdf(observation(p, a, sp), o))
    else
        return :(throw(MethodError(obs_weight, (p, a, sp, o))))
    end
end

@generated function obs_weight(p, sp, o)
    if implemented(observation, Tuple{p, sp})
        return :(pdf(observation(p, sp), o))
    else
        return :(throw(MethodError(obs_weight, (p, sp, o))))
    end
end

function implemented(f::typeof(obs_weight), TT::Type)
    m = which(f, TT)
    if length(TT.parameters) == 5
        P, S, A, _, O = TT.parameters
        reqs_met = implemented(observation, Tuple{P,S,A,S}) || implemented(obs_weight, Tuple{P,A,S,O})
    elseif length(TT.parameters) == 4
        P, A, S, O = TT.parameters
        reqs_met = implemented(observation, Tuple{P,A,S}) || implemented(obs_weight, Tuple{P,S,O})
    elseif length(TT.parameters) == 3
        P, S, O = TT.parameters
        reqs_met = implemented(observation, Tuple{P,S})
    else
        return method_exists(f, TT)
    end
    if m.module == ParticleFilters && !reqs_met
        return false
    else
        true
    end
end
