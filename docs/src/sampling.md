# Sampling

One of the easiest performance mistakes to make when first implementing particle filters is inefficient resampling. Using off-the-shelf functions that sequentially draw samples from a categorical distribution can easily result in $O(n^2)$ or even $O(n^3)$ resampling. Fortunately $O(n)$ or $O(n)\log(n)$ algorithms exist for this task.

This package has two features to improve sampling.

First, by default, calling [`rand`](@ref) on a [`WeightedParticleBelief`](@ref) uses an [alias table](https://en.wikipedia.org/wiki/Alias_method) to sample according to the weights. This is an $O(n)$ algorithm that is particularly efficient when the number of samples is large. The Alias table is constructed in $O(n\log(n))$ time, and taking uncorrelated samples using the table is $O(1)$.

Second, the [`low_variance_sample`](@ref) function implements the algorithm described on page 110 of *Probabilistic Robotics* by Thrun, Burgard, and Fox. This $O(n)$ algorithm produces a low-variance set of samples distributed throughout the collection. This method is used by default in the [`BootstrapFilter`](@ref).

```@docs
low_variance_sample
```
