using OrdinaryDiffEq, Test, DiffEqDevTools
using LinearAlgebra, Random

# Build an ODE defined by a time-dependent linear operator
function update_func(A,u,p,t)
    A[1,1] = cos(t)
    A[2,1] = sin(t)
    A[1,2] = cos(t)*sin(t)
    A[2,2] = sin(t)^2
end
A = DiffEqArrayOperator(ones(2,2),update_func=update_func)
prob = ODEProblem(A, ones(2), (ti, 5.))
dts = 1 ./2 .^(10:-1:1)
sol  = solve(prob,OrdinaryDiffEq.MagnusMidpoint(),dt=1/4)

#sim  = test_convergence(dts,prob,OrdinaryDiffEq.MagnusMidpoint())
#@test sim.𝒪est[:l2] ≈ 2 atol=0.2

#=
## Midpoint splitting convergence
##
## We use the inhomogeneous Lorentz equation for an electron in a
## time-dependent field. To write this on matrix form and simplify
## comparison with the analytic solution, we introduce two dummy
## variables:
## 1) As the third component, a one is stored to allow the
##    inhomogeneous part to be expressed on matrix form.
## 2) As the fourth component, the initial time t_i is stored,
##    for use by the analytical formula.
## This wastes a lot of space, but simplifies the error analysis.
##
## We can then write the Lorentz equation as q̇ = [A + f(t)B]q.

f = (A,u,p,t) -> -sin(2pi*t)
F = (A,u,p,t) -> cos(2pi*t)/2pi # Primitive function of f(t)

A = DiffEqArrayOperator([0 1 0 0
           0 0 0 0
           0 0 0 0
           0 0 0 0])

B = DiffEqArrayOperator([0 0 0 0
           0 0 1 0
           0 0 0 0
           0 0 0 0],update_func=f)

H = AffineDiffEqOperator{Float64}((A,B),(),rand(4))

update_coefficients!(H,nothing,nothing,1)
H

function p(::Type{Val{:analytic}},u0,p,t)
    x0,v0 = u0[1:2]
    ti = u0[end]
    x = x0 + (t-ti)*v0 - (f.(t)-f(ti))/(2pi)^2 - (t-ti)*F(ti)
    v = v0 + (F.(t)-F(ti))
    [x, v, 1, ti]
end

x0,v0,ti = rand(3)
prob = ODEProblem(H, [x0, v0, 1, ti], (ti, 5.))
dts = 1 ./2 .^(10:-1:1)
sim  = test_convergence(dts,prob,OrdinaryDiffEq.MagnusMidpoint(krylov=true))
@test sim.𝒪est[:l2] ≈ 2 atol=0.2
=#

# Linear exponential solvers
prob = ODEProblem(A,u0,(0.0,1.0))
sol1 = solve(prob, LinearExponential(krylov=:off))(1.0)
sol2 = solve(prob, LinearExponential(krylov=:simple))(1.0)
sol3 = solve(prob, LinearExponential(krylov=:adaptive))(1.0)
sol_analytic = exp(1.0 * Matrix(A)) * u0

@test isapprox(sol1, sol_analytic, rtol=1e-10)
@test isapprox(sol2, sol_analytic, rtol=1e-10)
@test isapprox(sol3, sol_analytic, rtol=1e-10)
