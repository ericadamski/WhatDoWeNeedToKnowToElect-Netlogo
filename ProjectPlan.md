# Project Plan

#### Written By
* Eric Adamksi
* Blaine Thompson

## Algorithm Model

* Witten in Netlogo
* General Principle :
  * - [x] Create a random connect directed graph with a given population size ( slider )
  * - [x] Model the REACH Algorithm mentioned in the paper
  * - [x] Model the Leader Elect algorithm mentioned in the paper
  * - [x] Added Distance to channels and add a Time-To-Live to messages

## Algorithm Analysis

* - [x] Title ( Real-Time Analysis of the Leader Election Algorithm Provided in 'What Do We Need To Know To Elect In a Network With Unknown Participants' )
* - [x] Abstract
* - [ ] Defenition of Distributed Algorithms
* - [x] Intro : Our project idea in relation to the research paper
* - [ ] Model ( see model in research paper )
  * Test Properties :
  ```
    Run this test for the regular algorithm and the modified one for comparison.
    ============================================================================
    Sample Size of 20 random graphs
    population sizes of 10 ( This takes resonably long )
    upper limit on time 10, 000 ticks. ( ticks will simulate 1 seconds ) ( can possibly change )
    we shall calculate the theoretical running time and message complexity
    then we shall run 20 tests and compare our results to the theoretical formulas
    we should also note that adding a time delay will not change the outcome of the algorithm,
    base on the isolation lemma ( which can be found in the paper )
  ```
  * Comparison of the papers model to our model
    * Msg Passing Model -> added distance
    * Process IDs -> same
    * Port Labeling -> same
    * Graph Labeling -> same
    * Distributed Algorithm -> same with mention of addition of distance maybe
    * Execution Representaion -> same
    * Algorithm Properties -> same
    * Knowledge -> same
    * Remains Universal -> give explanation
  ( For all same above restate in your own words the general idea )
* - [ ] Body
  * There seems to be an overhead of time we need to consider to build the network using a type of flood-echo algorithm ( Talk to me about this if you need help )
  * You may need to program in some more funcitons to help plot the msg complexity and such.
  * Analyize multiple runs of the leader election algorithm, plot number of nodes, number of ticks, number of messages come up with time analysis ( big O notation ) and message complexity ( big O notation ) we need to discuss the theorectical formulas before hand. Then we can compare our results and discuss them. Explain some faults in our process and maybe some faults in the algorithm.
* - [ ] Conclusion
  * Link back to main paper abstract, compare or prove why our test did or did not work
  * how this relates to real world

* - [x] Sources -> obviously the research paper
