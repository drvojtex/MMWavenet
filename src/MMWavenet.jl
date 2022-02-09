module MMWavenet

using BSON
using Shuffle

export main
export save_dataset, load_dataset
export convert_jsons_2_pickle_samples            

include("network.jl")
include("dataset.jl")

@doc """
    main(sample_len::Int64, sample_features::Int64, path::String)

Creates neural network for sample shape ('sample_len', 'sample_features', batch). 
Loads BSON dataset from 'path' and train network. Returns network and its parametres.
""" ->
function main(sample_len::Int64, sample_features::Int64, path::String)
                            
    wavenet, θ = build_wavenet(sample_features, sample_len);

    trn_dataset, val_dataset = load_dataset(path)

    train!(θ, trn_dataset, val_dataset, iter=200)

    println("Confusion matrix for validation data.")
    print_conmat(Vector{Float64}(wavenet(val_data)'[:,1]), Vector{Int64}(val_labels), true)
    print_conmat(Vector{Float64}(wavenet(val_data)'[:,1]), Vector{Int64}(val_labels), false)

    return wavenet, Θ
end

end 
