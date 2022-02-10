# MMWavenet

[![Run tests](https://github.com/kozvojtex/MMWavenet/actions/workflows/RunTests.yml/badge.svg)](https://github.com/kozvojtex/MMWavenet/actions/workflows/RunTests.yml)

[![codecov](https://codecov.io/gh/kozvojtex/MMWavenet/branch/master/graph/badge.svg?token=LO7YSB4L1I)](https://codecov.io/gh/kozvojtex/MMWavenet)

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
The repository is organised as follows. In the src folder are source scripts: network.jl (implementation of the whole MMWavenet), prepare_sample.jl (extracts features of packets from pcap file and stores them into pickle format), dataset.jl (collects pickle samples and stores them into bson dataset file) and MMWavenet.jl (main script to build and train neural network). In the examples folder an example.jl script that shows how to load the dataset and train neural network (and also includes benchmark of training). In the test folder is a script to test the gradient computation of neural network by comparing automatic differentiation with finite differentiation (Central Difference Approximation). 
