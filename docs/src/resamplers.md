# Resamplers

One of the easiest performance mistakes to make when first implementing particle filters is inefficient resampling. Using off-the-shelf functions that sequentially draw samples from a categorical distribution can easily result in $O(n^2)$ or even $O(n^3)$ resampling. Fortunately simple $O(1)$ algorithms exist for this task.

In particular the algorithm described on page 110 of *Probabilistic Robotics* by Thrun, Burgard, and Fox has this property and also produces a low-variance set of samples distributed throughout the collection. This algorithm is implemented by the [`LowVarianceResampler`](@ref). Additionally ParticleFilters.jl contains the [`ImportanceResampler`](@ref) for comparison.


New resamplers can be created by implementing the [`resample`](@ref) function for a new type. This is especially important for [handling particle depletion](@ref Handling-Particle-Depletion).
