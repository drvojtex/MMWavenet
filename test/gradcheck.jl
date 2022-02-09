
using Test
using MMWavenet
using Flux


@doc """
    numgrad(model, data::Array{Float32, 3})

Returns gradient obtained by finite differentiation.
""" ->
function numgrad(model, data::Array{Float32, 3})
    gradient = Array{Float32, 3}(zeros(size(data)))
    for i=1:size(data)[1]
        for j=1:size(data)[2]
            Δ::Array{Float32, 3} = Array{Float32, 3}(zeros(size(data)))
            Δ[i, j, 1] = 10e-6
            gradient[i, j, 1] = cda(model, data, Δ)
        end
    end
    return gradient
end

@doc """
    cda(model, x::Array{Float32, 3})

Central Difference Approximations.
""" ->
function cda(model, x::Array{Float32, 3}, Δ::Array{Float32, 3})
    return (model(x+Δ)-model(x-Δ))/(2*maximum(Δ))
end

function gradcheck()
    m, _ = build_wavenet(4, 256);
    @testset "gradcheck" begin
        for _=1:10
            x::Array{Float32, 3} = randn(256, 4, 1)
            @test ((numgrad(m, x) .- gradient(m, x)[1]) .< 10e-4)
        end
    end
end
