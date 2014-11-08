WhatDoWeNeedToKnowToElect-Netlogo
=================================

A model based on the research paper : 
#####'What Do We Need to Know to Elect in Networks with Unknown Participants?' 
>Jérémie Chalopin, Emmanuel Godard and Antoine Naudin*

>LIF, Université Aix-Marseille and CNRS

###Some Important Notation
  * H ⊑↓ G 
      - a subgraph H of G is a subgraph closed by successors of G
  * ⊥
      - a port number
  * Succ(v)
      - a successor list given by { id(v') | v' ∈ next(v) } ( all neighbours with edges from v )
  * M
      - a mailbox
  * Coverd(M)
      - for an id(v) there is a pair (id(v), Succ(v)) ∈ M i.e { id(v) | (id(v), Succ(v)) ∈ M }
  * View(M)
      - (for an id(v) there exists a pair (id(v), Succs(v)) ∈ M AND id(v) is in Succ(v)) Union Coverd(M)
  * Vc
      - View(M)
  * Ec
      - for a pair ( id, id' ) the pair ( id, Succ ) ∈ M AND id' ∈ Succ i.e { (id, id') | (id,Succ) ∈ M and id' ∈ Succ }
  * C(M)
      - (Vc,Ec)
