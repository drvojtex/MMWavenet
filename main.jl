
using BSON
using Shuffle

include("network.jl")

# dataset setup
sample_len = 256;
sample_features = 4;
class_no = 1;
dataset_split = 0.8

dataset = BSON.load("/largeandslow/kozel/dataset/dataset_s.bson")
dataset[:m] = permutedims(dataset[:m], (2,1,3))
dataset[:m] = dataset[:m][:,:,shuffle(1:end)]
dataset[:c] = permutedims(dataset[:c], (2,1,3))
dataset[:c] = dataset[:c][:,:,shuffle(1:end)]

trn_mal = dataset[:m][:,:,1:Int64(floor(dataset_split*size(dataset[:m])[3]))]
val_mal = dataset[:m][:,:,Int64(floor(dataset_split*size(dataset[:m])[3])):end]
trn_clean = dataset[:c][:,:,1:Int64(floor(dataset_split*size(dataset[:m])[3]))]
val_clean = dataset[:c][:,:,Int64(floor(dataset_split*size(dataset[:m])[3])):end]

trn_data = Array{Float32, 3}(cat(trn_mal, trn_clean; dims=3))
val_data = Array{Float32, 3}(cat(val_mal, val_clean; dims=3))
trn_labels = Vector{Int64}(cat(ones(size(trn_mal)[3]), zeros(size(trn_clean)[3]); dims=1))
val_labels = Vector{Int64}(cat(ones(size(val_mal)[3]), zeros(size(val_clean)[3]); dims=1))

trn_dataset = (trn_data, trn_labels) 
val_dataset = (val_data, val_labels)

wavenet, θ = build_wavenet(sample_features, sample_len, kernel_size=1, out_dim=class_no);

train!(θ, trn_dataset, val_dataset, iter=200)

print_conmat(Vector{Float64}(wavenet(val_data)'[:,1]), Vector{Int64}(val_labels), true)
print_conmat(Vector{Float64}(wavenet(val_data)'[:,1]), Vector{Int64}(val_labels), false)

#using Plots
#rocplot(val_labels, Vector{Float64}((wavenet(val_data)[1,:])))

bson("targets_scores_s.bson", Dict(:t=>Vector{Int64}(val_labels), :s=>Vector{Float64}(wavenet(val_data)'[:,1])))
