using POMDPs, POMDPModels, BasicPOMCP, ParticleFilters

m = TigerPOMDP()
solver = POMCPSolver(tree_queries=10_000, c=100.0)
planner = solve(solver, m)
pf = BootstrapFilter(m, 10_000)
b = initialize_belief(pf, initialstate(m))

a = action(planner, b)

b = initialize_belief(pf, initialstate(m))
@profview for i in 1:100
    action(planner, initialize_belief(pf, initialstate(m)))
end
