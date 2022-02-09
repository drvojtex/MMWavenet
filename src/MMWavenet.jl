module MMWavenet

using BSON
using Shuffle

export main, build_wavenet, train!
export save_dataset, load_dataset
export convert_jsons_2_pickle_samples            

include("network.jl")
include("dataset.jl")

@doc """
    main(sample_len::Int64, sample_features::Int64, path::String)

Creates neural network for sample shape ('sample_len', 'sample_features', batch). 
Loads BSON dataset from 'path' and train network. Returns network and its parametres. 
'itr' is number of training iterations (default 10).
""" ->
function main(sample_len::Int64, sample_features::Int64, path::String; itr::Int64=10)
                            
    wavenet, θ = build_wavenet(sample_features, sample_len);

    trn_dataset, val_dataset = load_dataset(path)

    train!(θ, wavenet, trn_dataset, val_dataset, iter=itr)

    println("Confusion matrix for validation data.")
    print_conmat(Vector{Float64}(wavenet(val_dataset[1])'[:,1]), Vector{Int64}(val_dataset[2]), true)
    print_conmat(Vector{Float64}(wavenet(val_dataset[1])'[:,1]), Vector{Int64}(val_dataset[2]), false)

    return wavenet, θ
end

end 
