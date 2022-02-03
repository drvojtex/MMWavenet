# MMWavenet



             +---+         
             |V7 |         
             +---+         
               |           
               v           
           +-------+       
           |  V1   |       
           +-------+       
             |  ||         
         -----  |--------  
         |      ---     |  
         v        |     |  
      +-----+     |     |  
      | V2  |     |     |  
      +-----+     |     |  
        | |       |     |  
      --- ---     |     |  
      |     |     |     |  
      v     v     v     v  
    +---+ +---+ +---+ +---+
    |V5 | |V6 | |V4 | |V3 |
    +---+ +---+ +---+ +---+



       |                                               |
       |                                               |
       |                                               |
       +----------------------+------------------------+
Residual block                ^
                              |         Skip-connection
                              +------------------------>
                              |
                              +
        AdaptiveMeanPool+--->sum<---+AdaptiveMaxPool
                ^             ^             ^
                |             |             |
                +---------------------------+
                              |
Residual block                |
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
</span>
<span style="color: grey">                                                                                      +---+
        Skip-connections                                                                    |
    +-------------------->  Conv1D (ks=1, filters=>1, stride=1) +----> Dense (out_dim=1)    |
                                                                                            |
    +-------------------->  - - - - - - - - - - - - - - - - - -                             +-->  Dense (out_dim=1)
                                                                                            |
    +-------------------->                                                                  |
                                                                                            |
                                                                                        +---+
</span>
