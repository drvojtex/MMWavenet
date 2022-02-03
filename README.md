# MMWavenet


       |                                               |
       |                                               |
       |                                               |
       +----------------------+------------------------+
        R                      ^
                              |         Skip-connection
                              +------------------------>
                              |
                              +
        AdaptiveMeanPool+--->sum<---+AdaptiveMaxPool
                ^             ^             ^
                |             |             |
                +---------------------------+
                              |
        R                      |
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
    input - shape=(sample dimension, features count, batch)

                                                                                        +---+
        Skip-connections                                                                    |
    +-------------------->  Conv1D (ks=1, filters=>1, stride=1) +----> Dense (out_dim=1)    |
                                                                                            |
    +-------------------->  - - - - - - - - - - - - - - - - - -                             +-->  Dense (out_dim=1)
                                                                                            |
    +-------------------->                                                                  |
                                                                                            |
                                                                                        +---+

