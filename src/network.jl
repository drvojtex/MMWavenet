
using Flux
using StatsBase, Statistics, IterTools
using Flux: Data.DataLoader
using Printf, EvalMetrics


@doc """
    residual_block(f::Int64, ks::Int64)

Create residual block of `f` filters and `ks` kernel-size.
""" ->
function residual_block(f::Int64, ks::Int64)
    sigmoid_tanh = Chain(x->σ.(x) .* tanh.(x))
    return Chain(
        Dropout(0.1),
        Conv((ks,), f => f, identity; stride=ks),
        sigmoid_tanh,
        Conv((1,), f => f, identity; stride=1)
    )
end

@doc """
    build_wavenet(features::Int64, in_dim::Int64;
                     filters::Int64=5, kernel_size::Int64=2, out_dim::Int64)

Build the wavenet-nn for samples which consists of `in_dim` sub-samples and each sub sample has got `features` dimension. 
The `filters` and `kernel_size` are numbers of filters and kernel size for each convolution, `out_dim` is number of target classes. 
Returns the model.
""" ->
function build_wavenet(features::Int64, in_dim::Int64; filters::Int64=12, kernel_size::Int64=2, out_dim::Int64=1)
    
    parts = []
    
    stack_conv1d = Conv((1,), features=>filters, identity; stride=1)
    append!(parts, [stack_conv1d])
    
    res_blocks = []
    res_connetcions_mean = []
    res_connetcions_max = []
    res_lc_coefs = []
    res_blocks_cnt::Int64 = in_dim
    
    #=
    Create residual blocks.
    =#
    while res_blocks_cnt >= kernel_size
        res_block = residual_block(filters, kernel_size)
        append!(res_blocks, [res_block])
        res_blocks_cnt = Int(floor(res_blocks_cnt / kernel_size))
        
        a = 1.0
        b = 1.0
        append!(res_connetcions_mean, [Chain(AdaptiveMeanPool((res_blocks_cnt,)), x-> x.*a)])
        append!(res_connetcions_max, [Chain(AdaptiveMaxPool((res_blocks_cnt,)), x-> x.*b)])
        append!(res_lc_coefs, [[a, b]])
    end
    
    #=
    Create skip blocks.
    =#
    skip_blocks = []
    for i=1:length(res_blocks)
        append!(skip_blocks, [Chain(Conv((1,), filters => 1, identity; stride=1), 
                                    Flux.flatten,
                                    Dense(Int(floor(in_dim/2^i)), 1, identity))])
    end
    σ_ = Chain(x->x.+0.5, x->σ.(x))
    final = Chain(Dense(length(skip_blocks)+1, out_dim, σ_))
    append!(parts, [final])

    #=
    Connect blocks. 
    =#
    function model(x)
        x::Array{Float32, 3} = stack_conv1d(x)
        res_blocks_cnt = length(res_blocks)
        skip_connections = Array{Float32, 2}(zeros(1, size(x)[3]))
        for i::Int64=1:res_blocks_cnt
            x_res_block = res_blocks[i]
            x_max = res_connetcions_max[i]
            x_mean = res_connetcions_mean[i]
            x = Parallel(+, x_res_block, x_max, x_mean)(x, x, x)
            skip_connections = vcat(skip_connections, skip_blocks[i](x))
        end
        return final(skip_connections)
    end
    return model, Flux.params(
        parts, 
        res_blocks,
        res_lc_coefs,
        skip_blocks
    )
end

loss_mse(x, y) = Flux.mse(wavenet(x)', y)
acc_t(x, y, t) = sum((wavenet(x) .> t) .== y')/length(y)

function train!(ps, trn::Tuple{Array{Float32, 3}, Vector{Int64}}, val::Tuple{Array{Float32, 3}, Vector{Int64}}; 
                    loss=loss_mse, acc=acc_t, threshold::Float64=0.5, iter::Int64=100)
    X, Y = trn[1], trn[2]
    x, y = val[1], val[2]
    for i=1:iter
        gs = gradient(() -> loss(X, Y), ps)
        Flux.Optimise.update!(ADAM(), ps, gs)
        if i%10 == 0 
            @printf "iter: %d/%d, trn_loss: %.4f, trn_acc: %.2f; val_loss: %.4f, val_acc: %.2f\n" i iter loss(X, Y) acc(X, Y, threshold) loss(x, y) acc(x, y, threshold)
            @printf "trn_auc %.2f, val_auc %.2f\n\n" binary_eval_report(Y, Vector{Float64}((wavenet(X)[1,:])))["au_roccurve"] binary_eval_report(y, Vector{Float64}((wavenet(x)[1,:])))["au_roccurve"]

        end
    end
    ps
end

@doc """
    print_conmat(ŷ::Vector{Float64}, y::Vector{Int64}, absolut_values::Bool)

Print confusion matrix for predicted probabilities 'ŷ' (with treshold 0.5) and targets 'y'.
""" ->
function print_conmat(ŷ::Vector{Float64}, y::Vector{Int64}, absolut_values::Bool)
    cm = ConfusionMatrix(y, ŷ, 0.5)
    if absolut_values
        @printf "
        +---------------------+------------------+------------------+
        |          .          | Actual positives | Actual negatives |
        +---------------------+------------------+------------------+
        | Predicted positives | %12d     | %12d     |
        | Predicted negatives | %12d     | %12d     |
        +---------------------+------------------+------------------+
        \n" cm.tp cm.fp cm.fn cm.tn
    else
        total = cm.p+cm.n
        @printf "
        +---------------------+------------------+------------------+
        |          .          | Actual positives | Actual negatives |
        +---------------------+------------------+------------------+
        | Predicted positives |       %.2f       |       %.2f       |
        | Predicted negatives |       %.2f       |       %.2f       |
        +---------------------+------------------+------------------+
        \n" cm.tp/total cm.fp/total cm.fn/total cm.tn/total
    end
end
