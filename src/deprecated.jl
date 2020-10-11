@deprecate SIRParticleFilter(model, n::Int, rng::AbstractRNG) BootstrapFilter(model, n, rng)
@deprecate SIRParticleFilter(model, n::Int; rng::AbstractRNG=Random.GLOBAL_RNG) BootstrapFilter(model, n, rng)
