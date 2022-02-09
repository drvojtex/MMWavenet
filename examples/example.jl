
using MMWavenet
using BenchmarkTools

println("Learn MMWavenet on random dateset.")

network, ps = main(2, 3, "random_data.bson");
trn_dataset, val_dataset = load_dataset("random_data.bson")
@benchmark train!(ps, network, trn_dataset, val_dataset, iter=1)

