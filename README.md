# MMWavenet

[![Run tests](https://github.com/kozvojtex/MMWavenet/actions/workflows/RunTests.yml/badge.svg)](https://github.com/kozvojtex/MMWavenet/actions/workflows/RunTests.yml)

[![codecov](https://codecov.io/gh/kozvojtex/MMWavenet.jl/branch/master/graph/badge.svg?token=LO7YSB4L1I)](https://codecov.io/gh/kozvojtex/MMWavenet.jl)

The Mean-Max Wavenet neural network (MMWavenet) for classification of data arranged in a time-dependent series, where each sample of such a series may consist of multiple features. The MMWavenet consists of stacked residual block, after each residual block there is a MeanPool-MaxPool layer, which output continues to next residual block as well as to skip-connection. The skip-connections are processed by convolutions and dense layers to final output.

The input shape is in format (lenght of serie sample, features count, batch size). 

## Schema

       |                                               |
       |                                               |
       |                                               |
       +----------------------+------------------------+
        Residual block        ^
                              |         Skip-connection
                              +------------------------>
                              |
                              +
        AdaptiveMeanPool+--->sum<---+AdaptiveMaxPool
                ^             ^             ^
                |             |             |
                +---------------------------+
                              |
        Residual block        |
       +-----------------------------------------------+
       |                      +                        |
       |   Conv1D (ks=1, filters=>filters, stride=1)   |
       |                      ^                        |
       |                      |                        |
       |                      +                        |
       |                 +-->sum<--+                   |
       |                 |         |                   |
       |                 +         +                   |
       |              sigmoid     tanh                 |
       |                 ^         ^                   |
       |                 +----+----+                   |
       |                      |                        |
       |                      +                        |
       | Conv1D (ks=k_i, filters=>filters, stride=k_i) |
       |                      ^                        |
       |                      |                        |
       |                      +                        |
       |                 Dropout(0.1)                  |
       +----------------------+------------------------+
                              ^
                              |
             +----------------+-----------------+
             |                                  |
             | Conv1D (ks=1, features=>filters) |
             |                                  |
             +----------------+-----------------+
                              ^
                              |
                              +
    input - shape=(lenght of serie sample, features count, batch)

                                                                                        +---+
        Skip-connections                                                                    |
    +-------------------->  Conv1D (ks=1, filters=>1, stride=1) +----> Dense (out_dim=1)    |
                                                                                            |
    +-------------------->  - - - - - - - - - - - - - - - - - -                             +-->  Dense (out_dim=1)
                                                                                            |
    +-------------------->                                                                  |
                                                                                            |
                                                                                        +---+

## Repository
The repository is organised as follows: in the network.jl is implemented the whole MMWavenet. The scripts dataset.jl and prepare_sample.py are used to make dataset from given pcap files and store it into .bson format. The main.jl builds the neural network, loads dataset, train the network and shows result on validation data.



