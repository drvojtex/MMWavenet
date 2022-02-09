
using Pickle
using BSON

@doc """
    collect_samples(path::String)

Collect samples stored in pickle format in given 'path'.
""" ->
function collect_samples(path::String)
    names::Array{String} = readdir(path)
    dataset::Array{Float64, 3} = zeros(4, 256, 1)
    for name::String in names
        d::Matrix{Float64} = hcat(Pickle.load(open(join([path, name])))...)
        dataset = cat(dataset, d[:, 1:256, :]; dims=3)
    end
    return dataset[:,:,2:end];
end

@doc """
    save_dataset(mal_path::String, clean_path::String, path::String)

Load malware ('mal_path') and cleanware ('clean_path') samples. Collect them and save 
complete dataset in BSON format in given 'path'. 
""" ->
function save_dataset(mal_path::String, clean_path::String, path::String)
    malwares = collect_samples(mal_path)
    cleanwares = collect_samples(clean_path)
    bson(path, m = malwares, c = cleanwares)
end

@doc """
    load_dataset(path::String; dataset_split::Float64=0.8)

Load BSON dataset from given 'path' and split it to train and validation parts 
(default split coefficient 'dataset_split' is 0.8). Returns two tuples.
""" ->
function load_dataset(path::String; dataset_split::Float64=0.8)
    dataset = BSON.load(path)
    dataset[:m] = permutedims(dataset[:m], (2,1,3))
    dataset[:m] = dataset[:m][:,:,shuffle(1:end)]
    dataset[:c] = permutedims(dataset[:c], (2,1,3))
    dataset[:c] = dataset[:c][:,:,shuffle(1:end)]

    mal_cnt::Int64 = size(dataset[:m])[3]
    clean_cnt::Int64 = size(dataset[:c])[3]
    trn_mal = dataset[:m][:,:,1:Int64(floor(dataset_split*mal_cnt))]
    val_mal = dataset[:m][:,:,Int64(floor(dataset_split*mal_cnt)):end]
    trn_clean = dataset[:c][:,:,1:Int64(floor(dataset_split*clean_cnt))]
    val_clean = dataset[:c][:,:,Int64(floor(dataset_split*clean_cnt)):end]

    trn_data = Array{Float32, 3}(cat(trn_mal, trn_clean; dims=3))
    val_data = Array{Float32, 3}(cat(val_mal, val_clean; dims=3))
    trn_labels = Vector{Int64}(cat(ones(size(trn_mal)[3]), 
                        zeros(size(trn_clean)[3]); dims=1))
    val_labels = Vector{Int64}(cat(ones(size(val_mal)[3]), 
                        zeros(size(val_clean)[3]); dims=1))

    trn_dataset = (trn_data, trn_labels) 
    val_dataset = (val_data, val_labels)
    
    return trn_dataset, val_dataset
end
