
using Test
using MMWavenet
using Flux
using Statistics


@doc """
    numgrad(model, data::Array{Float32, 3})

Returns gradient obtained by finite differentiation.
""" ->
function numgrad(model, data::Array{Float32, 3})
    gradient = Array{Float32, 3}(zeros(size(data)))
    for i=1:size(data)[1]
        for j=1:size(data)[2]
            Δ::Array{Float32, 3} = Array{Float32, 3}(zeros(size(data)))
            Δ[i, j, 1] = mean(data)/100
            gradient[i, j, 1] = cda(model, data, Δ)[1]
        end
    end
    return gradient
end

@doc """
    cda(model, x::Array{Float32, 3})

Gradient: eighth order Central Difference Approximation.
""" ->
function cda(m, x::Array{Float32, 3}, Δ::Array{Float32, 3})
    return ((1/280)*m(x-4*Δ) - (4/105)*m(x-3*Δ) + (1/5)*m(x-2*Δ) - (4/5)*m(x-Δ)
    - (1/280)*m(x+4*Δ) + (4/105)*m(x+3*Δ) - (1/5)*m(x+2*Δ) + (4/5)*m(x+Δ) )/maximum(Δ)
end

function gradcheck()
    m, _ = build_wavenet(2, 3);
    
    # Finite differentiation vs Automatic differentiation.
    @testset "finiteDiff" begin
        for _=1:10
            x::Array{Float32, 3} = Array{Float32, 3}(rand(0:0.0001:0.001, (3, 2, 1)))
            @test median(abs.((numgrad(m, x) .- 
                gradient(Chain(m, t->t[1]), x)[1]))) < 10e-3
        end
    end
    
    # Gradients are not same for different inputs
    @testset "differentGrads" begin
        for _=1:2
            x1 = Array{Float32, 3}(rand(0:0.0001:0.001, (3, 2, 1)))
            x2 = Array{Float32, 3}(rand(0:0.0001:0.001, (3, 2, 1)))
            @test gradient(Chain(m, t->t[1]), x1)[1] != gradient(Chain(m, t->t[1]), x2)[1];
        end
    end
end

gradcheck()
