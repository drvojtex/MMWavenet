
using BSON
using Shuffle

include("network.jl")

sample_len = 256;
sample_features = 15;
class_no = 1;
#samples_cnt = 100;
#data = randn(Float32, sample_len, sample_features, samples_cnt);
#labels = rand(0:class_no, samples_cnt);

dataset = BSON.load("/largeandslow/kozel/dataset/dataset.bson")
dataset[:m] = permutedims(dataset[:m], (2,1,3))
dataset[:m] = dataset[:m][:,:,shuffle(1:end)]
dataset[:c] = permutedims(dataset[:c], (2,1,3))
dataset[:c] = dataset[:c][:,:,shuffle(1:end)]

dataset_split = 0.9
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

wavenet, θ = build_wavenet(sample_features, sample_len, kernel_size=2, out_dim=class_no);

train!(θ, trn_dataset, val_dataset, iter=1000)

print_conmat(Vector{Int64}((wavenet(val_data) .>= 0.5)'[:,1]), Vector{Int64}(val_labels), true)
print_conmat(Vector{Int64}((wavenet(val_data) .>= 0.5)'[:,1]), Vector{Int64}(val_labels), false)

#using Plots
#rocplot(labels, Vector{Float64}((wavenet(data)[1,:])))
