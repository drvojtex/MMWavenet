
import Pkg
Pkg.activate(normpath(joinpath(@__DIR__, ".")))
Pkg.update()

using MMWavenet

println("Learn MMWavenet on random dateset.")

main(256, 4, "random_data.bson");
