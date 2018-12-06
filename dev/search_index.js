var documenterSearchIndex = {"docs": [

{
    "location": "basic/#",
    "page": "Basic Particle Filter",
    "title": "Basic Particle Filter",
    "category": "page",
    "text": ""
},

{
    "location": "basic/#Basic-Particle-Filter-1",
    "page": "Basic Particle Filter",
    "title": "Basic Particle Filter",
    "category": "section",
    "text": ""
},

{
    "location": "basic/#Update-Steps-1",
    "page": "Basic Particle Filter",
    "title": "Update Steps",
    "category": "section",
    "text": "The basic particle filtering step in ParticleFilters.jl is implemented in the update function, and consists of three steps:Prediction (or propagation) - each state particle is simulated forward one step in time\nReweighting - an explicit measurement (observation) model is used to calculate a new weight\nResampling - a new collection of state particles is generated with particle frequencies proportional to the new weightsThis is an example of sequential importance resampling, and the SIRParticleFilter constructor can be used to construct such a filter with a model that controls the prediction and reweighting steps, and a number of particles to create in the resampling phase.A more flexible structure for building a particle filter is the BasicParticleFilter. It contains three models, one for each step:The predict_model controls prediction through predict!\nThe reweight_model controls reweighting through reweight!\nThe resampler controls resampling through resampleParticleFilters.jl contains implementations of these components that can be mixed and matched. In many cases the prediction and reweighting steps use the same model, for example a ParticleFilterModel or a POMDP.To carry out the steps individually without the need for pre-allocating memory or doing a full update step, the predict, reweight, and resample functions are provided."
},

{
    "location": "basic/#ParticleFilters.SIRParticleFilter",
    "page": "Basic Particle Filter",
    "title": "ParticleFilters.SIRParticleFilter",
    "category": "function",
    "text": "SIRParticleFilter(model, n, [rng])\n\nConstruct a sequential importance resampling particle filter.\n\nArguments\n\nmodel: a model for the prediction dynamics and likelihood reweighing, for example a POMDP or ParticleFilterModel\nn::Integer: number of particles\nrng::AbstractRNG: random number generator\n\nFor a more flexible particle filter structure see BasicParticleFilter.\n\n\n\n\n\n"
},

{
    "location": "basic/#ParticleFilters.BasicParticleFilter",
    "page": "Basic Particle Filter",
    "title": "ParticleFilters.BasicParticleFilter",
    "category": "type",
    "text": "BasicParticleFilter(predict_model, reweight_model, resampler, n_init::Integer, rng::AbstractRNG)\nBasicParticleFilter(model, resampler, n_init::Integer, rng::AbstractRNG)\n\nConstruct a basic particle filter with three steps: predict, reweight, and resample.\n\nIn the second constructor, model is used for both the prediction and reweighting.\n\n\n\n\n\n"
},

{
    "location": "basic/#POMDPs.update",
    "page": "Basic Particle Filter",
    "title": "POMDPs.update",
    "category": "function",
    "text": "update(updater::Updater, belief_old, action, observation)\n\nReturn a new instance of an updated belief given belief_old and the latest action and observation.\n\n\n\n\n\n"
},

{
    "location": "basic/#ParticleFilters.predict!",
    "page": "Basic Particle Filter",
    "title": "ParticleFilters.predict!",
    "category": "function",
    "text": "predict!(pm, m, b, u, rng)\npredict!(pm, m, b, u, y, rng)\n\nFill pm with predicted particles for the next time step.\n\nA method of this function should be implemented by prediction models to be used in a BasicParticleFilter. pm should be a correctly-sized vector created by particle_memory to hold a one-step-propagated particle for each particle in b.\n\nNormally the observation y is not needed, so most prediction models should implement the first version, but the second is available for heuristics that use y.\n\nArguments\n\npm::Vector: memory for holding the propagated particles; created by particle_memory and resized to n_particles(b).\nm: prediction model, the \"owner\" of this function\nb::ParticleCollection: current belief; each particle in this belief should be propagated one step and inserted into pm.\nu: control or action\nrng::AbstractRNG: random number generator; should be used for any randomness in propagation for reproducibility.\ny: measuerement/observation (usually not needed)\n\n\n\n\n\n"
},

{
    "location": "basic/#ParticleFilters.reweight!",
    "page": "Basic Particle Filter",
    "title": "ParticleFilters.reweight!",
    "category": "function",
    "text": "reweight!(wm, m, b, a, pm, y)\nreweight!(wm, m, b, a, pm, y, rng)\n\nFill wm likelihood weights for each particle in pm.\n\nA method of this function should be implemented by reweighting models to be used in a BasicParticleFilter. wm should be a correctly-sized vector to hold weights for each particle in pm.\n\nNormally rng is not needed, so most reweighting models should implement the first version, but the second is available for heuristics that use random numbers.\n\nArguments\n\nwm::Vector{Float64}: memory for holding likelihood weights.\nm: reweighting model, the \"owner\" of this function\nb::ParticleCollection: previous belief; pm should contain a propagated particle for each particle in this belief\nu: control or action\npm::Vector: memory for holding current particles; these particle have been propagated by predict!.\ny: measurement/observation\nrng::AbstractRNG: random number generator; should be used for any randomness for reproducibility.\n\n\n\n\n\n"
},

{
    "location": "basic/#ParticleFilters.resample",
    "page": "Basic Particle Filter",
    "title": "ParticleFilters.resample",
    "category": "function",
    "text": "resample(resampler, bp::AbstractParticleBelief, rng::AbstractRNG)\n\nSample a new ParticleCollection from bp.\n\nGeneric domain-independent resamplers should implement this version.\n\nresample(resampler, bp::WeightedParticleBelief, predict_model, reweight_model, b, a, o, rng)\n\nSample a new particle collection from bp with additional information from the arguments to the update function.\n\nThis version defaults to resample(resampler, bp, rng). Domain-specific resamplers that wish to add noise to particles, etc. should implement this version.\n\n\n\n\n\n"
},

{
    "location": "basic/#ParticleFilters.predict",
    "page": "Basic Particle Filter",
    "title": "ParticleFilters.predict",
    "category": "function",
    "text": "predict(m, b, u, rng)\n\nSimulate each of the particles in b forward one time step using model m and contol input u returning a vector of states. Calls predict! internally - see that function for documentation.\n\n\n\n\n\n"
},

{
    "location": "basic/#ParticleFilters.reweight",
    "page": "Basic Particle Filter",
    "title": "ParticleFilters.reweight",
    "category": "function",
    "text": "reweight(m, b, u, pm, y)\n\nReturn a vector of likelihood weights for each particle in pm given observation y.\n\npm can be generated with predict(m, b, u, rng).\n\n\n\n\n\n"
},

{
    "location": "basic/#ParticleFilters.particle_memory",
    "page": "Basic Particle Filter",
    "title": "ParticleFilters.particle_memory",
    "category": "function",
    "text": "particle_memory(m)\n\nReturn a suitable container for particles produced by prediction model m.\n\nThis should usually be an empty Vector{S} where S is the type of the state for prediction model m. Size does not matter because resize! will be called appropriately within update.\n\n\n\n\n\n"
},

{
    "location": "basic/#Docstrings-1",
    "page": "Basic Particle Filter",
    "title": "Docstrings",
    "category": "section",
    "text": "SIRParticleFilter\nBasicParticleFilter\nupdate\npredict!\nreweight!\nresample\npredict\nreweight\nparticle_memory"
},

{
    "location": "beliefs/#",
    "page": "Beliefs",
    "title": "Beliefs",
    "category": "page",
    "text": ""
},

{
    "location": "beliefs/#Beliefs-1",
    "page": "Beliefs",
    "title": "Beliefs",
    "category": "section",
    "text": ""
},

{
    "location": "beliefs/#ParticleFilters.ParticleCollection",
    "page": "Beliefs",
    "title": "ParticleFilters.ParticleCollection",
    "category": "type",
    "text": "ParticleCollection{S}\n\nUnweighted particle belief consisting of equally important particles of type S.\n\n\n\n\n\n"
},

{
    "location": "beliefs/#ParticleFilters.WeightedParticleBelief",
    "page": "Beliefs",
    "title": "ParticleFilters.WeightedParticleBelief",
    "category": "type",
    "text": "WeightedParticleBelief{S}\n\nWeighted particle belief consisting of particles of type S and their associated weights.\n\n\n\n\n\n"
},

{
    "location": "beliefs/#Types-1",
    "page": "Beliefs",
    "title": "Types",
    "category": "section",
    "text": "ParticleFilters.jl provides two types of particle beliefs. ParticleCollection is little more than a vector of unweighted particles. WeightedParticleBelief allows for different weights for each of the particles.Both are subtypes of AbstractParticleBelief and implement the same particle belief interface. For probability mass calculations (the pdf function), a dictionary containing the normalized sum of weights for all identical particles is created on the first call and cached for efficient future querying.ParticleCollection\nWeightedParticleBelief"
},

{
    "location": "beliefs/#Interface-1",
    "page": "Beliefs",
    "title": "Interface",
    "category": "section",
    "text": ""
},

{
    "location": "beliefs/#Standard-POMDPs.jl-Distribution-Interface-1",
    "page": "Beliefs",
    "title": "Standard POMDPs.jl Distribution Interface",
    "category": "section",
    "text": "The following functions from the POMDPs.jl distributions interface provide basic ways of interacting with particle beliefs as distributions (click on each for documentation):rand\npdf\nsupport\nsampletype (will be replaced with Random.gentype)\nmode\nmean"
},

{
    "location": "beliefs/#Particle-Interface-1",
    "page": "Beliefs",
    "title": "Particle Interface",
    "category": "section",
    "text": "These functions provide access to the particles and weights in the beliefs (click on each for docstrings):n_particles\nparticles\nweights\nweighted_particles\nweight_sum\nweight\nparticle\nParticleFilters.probdict"
},

{
    "location": "beliefs/#Base.rand",
    "page": "Beliefs",
    "title": "Base.rand",
    "category": "function",
    "text": "rand{T}(rng::AbstractRNG, d::Any)\n\nReturn a random element from distribution or space d.\n\nIf d is a state or transition distribution, the sample will be a state; if d is an action distribution, the sample will be an action or if d is an observation distribution, the sample will be an observation.\n\n\n\n\n\n"
},

{
    "location": "beliefs/#Distributions.pdf",
    "page": "Beliefs",
    "title": "Distributions.pdf",
    "category": "function",
    "text": "pdf(d::Any, x::Any)\n\nEvaluate the probability density of distribution d at sample x.\n\n\n\n\n\n"
},

{
    "location": "beliefs/#Distributions.support",
    "page": "Beliefs",
    "title": "Distributions.support",
    "category": "function",
    "text": "support(d::Any)\n\nReturn the possible values that can be sampled from distribution d. Values with zero probability may be skipped.\n\n\n\n\n\n"
},

{
    "location": "beliefs/#POMDPs.sampletype",
    "page": "Beliefs",
    "title": "POMDPs.sampletype",
    "category": "function",
    "text": "sampletype(T::Type)\nsampletype(d::Any) = sampletype(typeof(d))\n\nReturn the type of objects that are sampled from a distribution or space d when rand(rng, d) is called.\n\nThe distribution writer should implement the sampletype(::Type) method for the distribution type, then the function can be called for that type or for objects of that type (i.e. the sampletype(d::Any) = sampletype(typeof(d)) default is provided).\n\n\n\n\n\n"
},

{
    "location": "beliefs/#StatsBase.mode",
    "page": "Beliefs",
    "title": "StatsBase.mode",
    "category": "function",
    "text": "mode(d::Any)\n\nReturn the most likely value in a distribution d.\n\n\n\n\n\n"
},

{
    "location": "beliefs/#Statistics.mean",
    "page": "Beliefs",
    "title": "Statistics.mean",
    "category": "function",
    "text": "mean(d::Any)\n\nReturn the mean of a distribution d.\n\n\n\n\n\n"
},

{
    "location": "beliefs/#ParticleFilters.n_particles",
    "page": "Beliefs",
    "title": "ParticleFilters.n_particles",
    "category": "function",
    "text": "n_particles(b::AbstractParticleBelief)\n\nReturn the number of particles.\n\n\n\n\n\n"
},

{
    "location": "beliefs/#ParticleFilters.particles",
    "page": "Beliefs",
    "title": "ParticleFilters.particles",
    "category": "function",
    "text": "particles(b::AbstractParticleBelief)\n\nReturn an iterator over the particles.\n\n\n\n\n\n"
},

{
    "location": "beliefs/#ParticleFilters.weights",
    "page": "Beliefs",
    "title": "ParticleFilters.weights",
    "category": "function",
    "text": "weights(b::AbstractParticleBelief)\n\nReturn an iterator over the weights.\n\n\n\n\n\n"
},

{
    "location": "beliefs/#ParticleFilters.weighted_particles",
    "page": "Beliefs",
    "title": "ParticleFilters.weighted_particles",
    "category": "function",
    "text": "weighted_particles(b::AbstractParticleBelief)\n\nReturn an iterator over particle-weight pairs.\n\n\n\n\n\n"
},

{
    "location": "beliefs/#ParticleFilters.weight_sum",
    "page": "Beliefs",
    "title": "ParticleFilters.weight_sum",
    "category": "function",
    "text": "weight_sum(b::AbstractParticleBelief)\n\nReturn the sum of the weights of the particle collection.\n\n\n\n\n\n"
},

{
    "location": "beliefs/#ParticleFilters.weight",
    "page": "Beliefs",
    "title": "ParticleFilters.weight",
    "category": "function",
    "text": "weight(b::AbstractParticleBelief, i)\n\nReturn the weight for particle i.\n\n\n\n\n\n"
},

{
    "location": "beliefs/#ParticleFilters.particle",
    "page": "Beliefs",
    "title": "ParticleFilters.particle",
    "category": "function",
    "text": "particle(b::AbstractParticleBelief, i)\n\nReturn particle i.\n\n\n\n\n\n"
},

{
    "location": "beliefs/#ParticleFilters.probdict",
    "page": "Beliefs",
    "title": "ParticleFilters.probdict",
    "category": "function",
    "text": "probdict(b::AbstractParticleBelief)\n\nReturn a dictionary mapping states to probabilities.\n\nThe probability is the normalized sum of the weights for all matching particles.\n\nFor ParticleCollection and WeightedParticleBelief, the result is cached for efficiency so the calculation is only performed the first time this is called. There is a default implementation for all AbstractParticleBeliefs, but it is inefficient (it creates a new dictionary every time). New AbstractParticleBelief implementations should provide an efficient implementation.\n\n\n\n\n\n"
},

{
    "location": "beliefs/#Interface-Docstrings-1",
    "page": "Beliefs",
    "title": "Interface Docstrings",
    "category": "section",
    "text": "POMDPs.rand\nPOMDPs.pdf\nPOMDPs.support\nPOMDPs.sampletype\nPOMDPs.mode\nPOMDPs.mean\nn_particles\nparticles\nweights\nweighted_particles\nweight_sum\nweight\nparticle\nParticleFilters.probdict"
},

{
    "location": "depletion/#",
    "page": "Handling Particle Depletion",
    "title": "Handling Particle Depletion",
    "category": "page",
    "text": ""
},

{
    "location": "depletion/#Handling-Particle-Depletion-1",
    "page": "Handling Particle Depletion",
    "title": "Handling Particle Depletion",
    "category": "section",
    "text": "Many of the most common problems with particle filters are related to particle depletion, that is, a lack of particles corresponding to the true state. In many cases, it is not difficult to overcome these problems, but domain-specific heuristics are often more effective than generic approaches.The recommended first remedy for particle depletion is to write a custom domain-specific resampler that injects new appropriate particles in the case of particle depletion. The particle depletion can be detected by observing low likelihood weights and handling it within the resample function.The example below contains a more robust resampler for POMDP models. When it detects a complete particle depletion with weight_sum(bp) == 0.0, it replaces the particles by sampling from the initial state distribution.using POMDPs\nusing ParticleFilters\n\nstruct POMDPResampler\n    n::Int\nend\n\nfunction ParticleFilters.resample(r::POMDPResampler,\n                                  bp::WeightedParticleBelief,\n                                  pm::POMDP,\n                                  rm::POMDP,\n                                  b,\n                                  a,\n                                  o,\n                                  rng)\n\n    if weight_sum(bp) == 0.0\n        # no appropriate particles - resample from the initial distribution\n        new_ps = [initialstate(pm, rng) for i in 1:r.n]\n        return ParticleCollection(new_ps)\n    else\n        # normal resample\n        return resample(LowVarianceResampler(r.n), bp, rng)\n    end\nendIf it is not possible to handle particle depletions only within resample, then it may be possible to handle with a custom prediction or reweighting model, or it may be best to write a new filter using the building blocks in this package. A good way to get started on this is to look at the implementation of the update function of the BasicParticleFilter"
},

{
    "location": "#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "#Home-1",
    "page": "Home",
    "title": "Home",
    "category": "section",
    "text": "ParticleFilters.jl provides a basic particle filter representation along with some useful tools for constructing more complex particle filters.In particular it provides both weighted and unweighted particle belief types that implement the POMDPs.jl distribution interface including sampling and automatic caching of probability mass calculations.Additionally, an important requirement for a particle filter is efficient resampling. This package provides O(n) resamplers.Dynamics and measurement models for the filters can be specified as a ParticleFilterModel or a POMDP or a custom user-defined type.The simplest sequential-importance-resampling Particle filter can be constructed with SIRParticleFilter. BasicParticleFilter provides a more flexible structure.Basic setup of a model is as follows:using ParticleFilters, Distributions\n\ndynamics(x, u, rng) = x + u + randn(rng)\ny_likelihood(x_previous, u, x, y) = pdf(Normal(), y - x)\nmodel = ParticleFilterModel{Float64}(dynamics, y_likelihood)\npf = SIRParticleFilter(model, 10)Then the update function can be used to perform a particle filter update.b = ParticleCollection([1.0, 2.0, 3.0, 4.0])\nu = 1.0\ny = 3.0\n\nb_new = update(pf, b, u, y)There are tutorials for three ways to use the particle filters:As an estimator for feedback control,\nto filter time-series measurements, and\nas an updater for POMDPs.jl.For documentation on all aspects of the package, see the contents below."
},

{
    "location": "#Contents-1",
    "page": "Home",
    "title": "Contents",
    "category": "section",
    "text": ""
},

{
    "location": "models/#",
    "page": "Models",
    "title": "Models",
    "category": "page",
    "text": ""
},

{
    "location": "models/#Models-1",
    "page": "Models",
    "title": "Models",
    "category": "section",
    "text": "The BasicParticleFilter requires two pieces of information about the system that is being filtered:A generative dynamics model, which determines how the state will change (possibly stochastically) over time, and\nAn explicit model of the observation distribution.The ParticleFilterModel provides a standard structure for these two elements. The first parameter of the type, S, specifies the state type. The constructor arguments are two functions. The first, f, is the dynamics function, which produces the next state given the current state, control, and a random number generator as arguments. The second function, g is describes the weight that should be given to the particle given the original state, control, final state, and observation as arguments. See the docstring below and the feedback control and filtering tutorials for more info.ParticleFilters.jl requires the rng argument in the system dynamics functions for the sake of reproducibility independent of the simulation or control system.The dynamics and reweighting models may also be specified separately using PredictModel and ReweightModel.Note that a POMDP with generate_s and obs_weight implemented may also serve as a model."
},

{
    "location": "models/#ParticleFilters.ParticleFilterModel",
    "page": "Models",
    "title": "ParticleFilters.ParticleFilterModel",
    "category": "type",
    "text": "ParticleFilterModel{S}(f, g)\n\nCreate a system model suitable for use in a particle filter. This is a combination prediction/dynamics model and reweighting model.\n\nParameters\n\nS is the state type, e.g. Float64, Vector{Float64}\n\nArguments\n\nf is the dynamics function. xₜ₊₁ = f(xₜ, uₜ, rng) where x is the state, u is the control input, and rng is a random number generator.\ng is the observation weight function. g(xₜ, uₜ, xₜ₊₁, yₜ₊₁) returns the likelihood weight of measurement yₜ₊₁ given that the state transitioned from xₜ to xₜ₊₁ when control uₜ was applied. These weights need not be normalized (and, for performance, usually should not be).\n\n\n\n\n\n"
},

{
    "location": "models/#ParticleFilters.PredictModel",
    "page": "Models",
    "title": "ParticleFilters.PredictModel",
    "category": "type",
    "text": "PredictModel{S}(f::Function)\n\nCreate a prediction model for use in a BasicParticleFilter\n\nSee ParticleFilterModel for descriptions of S and f.\n\n\n\n\n\n"
},

{
    "location": "models/#ParticleFilters.ReweightModel",
    "page": "Models",
    "title": "ParticleFilters.ReweightModel",
    "category": "type",
    "text": "ReweightModel(g::Function)\n\nCreate a reweighting model for us in a BasicParticleFilter.\n\nSee ParticleFilterModel for a description of g.\n\n\n\n\n\n"
},

{
    "location": "models/#Docstrings-1",
    "page": "Models",
    "title": "Docstrings",
    "category": "section",
    "text": "ParticleFilterModel\nPredictModel\nReweightModel"
},

{
    "location": "resamplers/#",
    "page": "Resamplers",
    "title": "Resamplers",
    "category": "page",
    "text": ""
},

{
    "location": "resamplers/#ParticleFilters.ImportanceResampler",
    "page": "Resamplers",
    "title": "ParticleFilters.ImportanceResampler",
    "category": "type",
    "text": "ImportanceResampler(n)\n\nSimple resampler. Uses alias sampling to attain O(n log(n)) performance with uncorrelated samples.\n\n\n\n\n\n"
},

{
    "location": "resamplers/#ParticleFilters.LowVarianceResampler",
    "page": "Resamplers",
    "title": "ParticleFilters.LowVarianceResampler",
    "category": "type",
    "text": "LowVarianceResampler(n)\n\nLow variance sampling algorithm on page 110 of Probabilistic Robotics by Thrun Burgard and Fox. O(n) runtime, correlated samples, but produces a useful low-variance set.\n\n\n\n\n\n"
},

{
    "location": "resamplers/#Resamplers-1",
    "page": "Resamplers",
    "title": "Resamplers",
    "category": "section",
    "text": "One of the easiest performance mistakes to make when first implementing particle filters is inefficient resampling. Using off-the-shelf functions that sequentially draw samples from a categorical distribution can easily result in O(n^2) or even O(n^3) resampling. Fortunately simple O(1) algorithms exist for this task.In particular the algorithm described on page 110 of Probabilistic Robotics by Thrun, Burgard, and Fox has this property and also produces a low-variance set of samples distributed throughout the collection. This algorithm is implemented by the LowVarianceResampler. Additionally ParticleFilters.jl contains the ImportanceResampler for comparison.ImportanceResampler\nLowVarianceResamplerNew resamplers can be created by implementing the resample function for a new type. This is especially important for handling particle depletion."
},

]}
