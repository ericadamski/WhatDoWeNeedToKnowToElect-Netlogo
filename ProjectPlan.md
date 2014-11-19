# Project Plan

#### Written By
* Eric Adamksi
* Blaine Thompson

## Algorithm Model

* Witten in Netlogo
* General Principle :
  * - [x] Create a random connect directed graph with a given population size ( slider )
  * - [x] Model the REACH Algorithm mentioned in the paper
  * - [ ] Model the Leader Elect algorithm mentioned in the paper
  * - [x] Added Distance to channels and add a Time-To-Live to messages

## Algorithm Analysis

* - [x] Title
* - [x] Abstract
* - [ ] Defenition of Distributed Algorithms
* - [x] Intro : Our project idea in relation to the research paper
* - [ ] Model ( see model in research paper )
  * Test Properties :
  ```
    Run this test for the regular algorithm and the modified one for comparison.
    ============================================================================
    Sample Size of 20 random graphs
    population sizes of 10, 50 and 100 ( run 20 random graphs on each population size )
    upper limit on time 10, 000 ticks. ( ticks will simulate 1 seconds ) ( can possibly change )
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
  * Analyize multiple runs of the leader election algorithm, plot number of nodes, number of ticks, number of messages
    * Generate Statistics, avg, std.dev, mean, etc, that describe our tests
  * Change the base algorithm ( restate the algorithm in sudo code here! ) to include distance between nodes ( instead of distance = 1 ) run the same tests as above, with randomly generated graphs
    * Generate and analyize the statistcs of the modified algorithm, if this algorithm doesn't work, we should give a short proof about why.
    * See in paper 'A Necessary and Sufficient Condition' -> how it will help prove our hypothesis
* - [ ] Conclusion
  * Link back to main paper abstract, compare or prove why our test did or did not work
  * how this relates to real world

* - [x] Sources -> obviously the research paper
