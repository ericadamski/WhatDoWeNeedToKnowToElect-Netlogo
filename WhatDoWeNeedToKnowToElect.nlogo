globals [ selected-ids number-of-messages total-messages ]

breed [processes process] ;;Nodes
directed-link-breed [channels channel] ;;Edges

;; Each process can have multiple channels which are denoted by ports,
;; at these connections maybe directed or undirected. ( directed = one way communication,
;; undirected = two way communication )

;; sending always sends to all neighbours ( in contacts list ), receive only from a single
;; neighbour

;; is-leader? values
;;   follower
;;   leader
;;   undecided

processes-own [
  contacts-list ;; contains all the channels that the process knows about
  succ          ;; contains all neighbours that are known at the begining this will stay constant after setup
  ID            ;; ID is unique
  is-leader?    ;; a string which gives the leader state of the process
  message-queue ;; a queue of all received messages to handle one at a time
  mailbox       ;; a set of pairs of id's to Succ-lists of other processes
  super-mailbox ;; a set of tuples (id, Mailbox, is-leader?)
  done-send?    ;; a flag to tell if processes has done send phase initial value, false
]

channels-own [
  port-to          ;; the process which the channel goes to
  port-from        ;; the process which the channel comes from
  active?          ;; if the channel is currently in use by a process
  current-distance ;; length of the channel, will take time * distance to travel
]

to setup
  clear-all
  reset-ticks
  
  set number-of-messages 0
  set total-messages 0
  
  set selected-ids []
  ;;create processes
  ;;  assign them a random position within the window
  ;;  assign them an ID ( have to keep track of which IDs have been selected )
  setup-processes
  display-processes
  
  ;;Must create a connected graph
  ;;  randomly choose to create some edges and maintain a connected graph
  ;;  create channels list and update processes contact-lists
  setup-channels
  create-connected-graph
  display-channels
end

to go
  ifelse electing-leader?
  [ elect-leader ]
  [ reach ]
  
  display-processes
  display-channels
  
  set number-of-messages message-count
  
  tick
end

to clear
  clear-all
  reset-ticks
end

to run-tests
  show "Running union on [1 2 3 7 8] [1 2 3 4 5 6]"
  show assert union [1 2 3 7 8] [1 2 3 4 5 6] [7 8 4 5 6 1 2 3]
  show "Running union on [1 2 3 4 5 6] [1 2 3 7 8]"
  show assert union [1 2 3 4 5 6] [1 2 3 7 8] [4 5 6 7 8 1 2 3]
  show "Running intersection on [1 2 3 7 8] [1 2 3 4 5 6]"
  show assert intersection [1 2 3 7 8] [1 2 3 4 5 6] [1 2 3]
  show "Running intersection on [1 2 3 4 5 6] [1 2 3 7 8]"
  show assert intersection [1 2 3 4 5 6] [1 2 3 7 8] [1 2 3]
  show "Running difference on [1 2 3 7 8] [1 2 3 4 5 6]"
  show assert difference [1 2 3 7 8] [1 2 3 4 5 6] [7 8]
  show "Running difference on [1 2 3 4 5 6] [1 2 3 7 8]"
  show assert difference [1 2 3 4 5 6] [1 2 3 7 8] [4 5 6]
  show "Running union on [] [1 2 3 4]"
  show assert union [] [1 2 3 4] []
  show "Running union on [1 2 3 4] []"
  show assert union [1 2 3 4] [] []
  show "Running intersection on [] [1 2 3 4]"
  show assert intersection [] [1 2 3 4] []
  show "Running intersection on [1 2 3 4] []"
  show assert intersection [1 2 3 4] [] []
  show "Running difference on [] [1 2 3 4]"
  show assert difference [] [1 2 3 4] []
  show "Running difference on [1 2 3 4] []"
  show assert difference [1 2 3 4] [] [1 2 3 4]
  show "Running list-equal on [] [1 2 3 4]"
  show assert list-equal? [] [1 2 3 4] false
  show "Running list-equal on [1 2 3 4] []"
  show assert list-equal? [1 2 3 4] [] false
  show "Running list-equal on [] []"
  show assert list-equal? [] [] true
  show "Running list-equal on [1 2 3 4] [1 2 3 4]"
  show assert list-equal? [1 2 3 4] [1 2 3 4] true
  show "Running list-equal [1 2 3 4] [1 2 3 4 5]"
  show assert list-equal? [1 2 3 4] [1 2 3 4 5] false
  show "Running list-equal [1 2 3 4 5] [1 2 3 4]"
  show assert list-equal? [1 2 3 4 5] [1 2 3 4] false
end

;;;;;;;;;;;;;;;;;;;;;
;; Setup-Functions ;;
;;;;;;;;;;;;;;;;;;;;;

to setup-processes
  set-default-shape processes "circle"
  create-processes population-size
  ask processes [
    setxy random-pxcor random-pycor
    set ID get-new-id
    set contacts-list []
    set is-leader? "undecided"
    set message-queue []
    set mailbox []
    set super-mailbox []
    set succ []
    set done-send? false
  ]
end

to setup-channels
  ;; creates population-size * population-size many channels and hides them all
  no-display
  ask processes [
    let me self
    let remaining-processes [self] of processes with [ me != self ]
    foreach remaining-processes [
      create-channel-to ? [
        set port-from me
        set port-to ?
        set active? false
        set current-distance calculate-distance port-from port-to
      ]
    ]
  ]
  ask channels [ hide-link ]
  display
end

;;;;;;;;;;;;;;;;;;;;
;; Main Functions ;;
;;;;;;;;;;;;;;;;;;;;

to reach
  ask processes [ if not done-send? [ send-message ] ]    ;; send phase
  ask processes [ receive-reach-message ] ;; receive phase ;; display all active channels
end

to send-message
  ;;send mailbox to all neighbours in contacts
  
  ;;algorithm
  ;; loop through contacts
  ;; add my message into their message-queue
  
  ;; a message is [ ttl ,[id, mailbox] ]
  
  let me self
  
  foreach contacts-list [
    let message create-message get-channel me ?
    ask ? [
      set total-messages total-messages + 1
      set message-queue lput message message-queue
    ]
  ]
  
  set done-send? true
end

to receive-reach-message
  ;;get one message per round through message-queue
  ;;  if the id received is not in my contacts-list add it
  ;;  or if my mailbox is missing some entries from the received mailbox
  ;;  update my info and send my mailbox again
  
  ;; message looks like [ ttl, [message] ]
  if not empty? message-queue [
    let next-message first message-queue ;; see message above
    let current-time first next-message ;; ttl
    set message-queue remove next-message message-queue ;; remove the current message from the queue
    set next-message first but-first next-message ;; [message]
    
    ifelse current-time <= 0 [
      let sent-id first next-message
      let sent-mailbox last next-message
      
      let is-member member? get-process-with-id sent-id contacts-list
      let missing-members difference sent-mailbox mailbox
      
      if ( ( not is-member ) or ( not empty? missing-members ) ) [
        if ( not is-member ) [ set contacts-list lput get-process-with-id sent-id contacts-list ]
        if ( not empty? missing-members ) [
          set mailbox sentence mailbox missing-members
        ]
        send-message
        update-channels
      ] 
      let local-view View mailbox
      let local-cover Covered mailbox
      if( list-equal? local-view local-cover and is-leader? = "undecided" ) [ show c-of-m mailbox ]
    ]
    [
      set message-queue fput (list (current-time - 1) next-message) message-queue
    ]
  ]
end

to elect-leader
  ask processes [ if not done-send? [ send-message ] ]
  ask processes [ recieve-messages ]
end

to recieve-messages
  ;; see above for defenitions of variables
  if not empty? message-queue [
    let next-message first message-queue
    set message-queue remove next-message message-queue
    let current-time first next-message
    set next-message first but-first next-message
    
    ifelse current-time <= 0 [
      let sent-id first next-message
      let sent-super-mailbox last next-message
      
      let is-member? member? get-process-with-id sent-id contacts-list
      let diff-super-mailbox difference sent-super-mailbox super-mailbox
      
      if not is-member? or not empty? diff-super-mailbox [
        let sent-mailbox []
        
        foreach sent-super-mailbox [
          set sent-mailbox union sent-mailbox get-mailbox-from-super-mailbox ?
        ]
        
        set mailbox union mailbox sent-mailbox
        ;;show "Super-mailbox"
        ;;show super-mailbox
        ;;show "sent smailbox"
        ;;show sent-super-mailbox
        ;;show "my stuff"
        ;;show (list (list ID mailbox is-leader?))
        ;;show "first union"
        ;;show union super-mailbox sent-super-mailbox
        ;;show "union of union"
        ;;show union (list (list ID mailbox is-leader?)) union super-mailbox sent-super-mailbox
        set super-mailbox union union sent-super-mailbox super-mailbox (list (list ID mailbox is-leader?))
        
        if not is-member? [
          set contacts-list lput get-process-with-id sent-id contacts-list
        ]
        send-message
      ]
    ]
    [
      set message-queue fput (list (current-time - 1) next-message) message-queue
    ]
  ]
  let local-view View mailbox
  let local-cover Covered mailbox
  let local-c-of-m c-of-m mailbox
  ;;Leader check
  if is-leader? = "undecided" and n-vertex-characteristic-function mailbox and list-equal? local-view local-cover and ids-are-present [
    ifelse not already-leader and ID < get-lowest-id [
      set is-leader? "leader"
    ]
    [
      set is-leader? "follower"
    ]
    set super-mailbox union super-mailbox (list (list ID mailbox is-leader?))
    send-message
  ]
  update-channels
end

;;;;;;;;;;;;;;;;;;;;;;;
;; Display-Functions ;;
;;;;;;;;;;;;;;;;;;;;;;;

to display-processes
  no-display
  ask processes [
    if is-leader? = "undecided" [ set color white ]
    if is-leader? = "follower"  [ set color yellow ]
    if is-leader? = "leader"    [ set color green ]
  ]
  display
end

to display-channels
  no-display
  ask channels [
    hide-link
    if active? [ show-link ]
  ]
  display
end

;;;;;;;;;;;;;;;;;;;;;;
;; Helper-Functions ;;
;;;;;;;;;;;;;;;;;;;;;;

to update-channels
  let me self
  foreach contacts-list [
    if not (me = ?) [
      ask get-channel me ? [
        if not active? [ set active? true ]
      ]
    ]
  ]
end

to-report get-new-id
  let random-id random(population-size ^ 3)
  
  while [ member? random-id selected-ids ] [
    set random-id random(population-size ^ 3)
  ]
  
  set selected-ids lput random-id selected-ids
  
  report random-id
end

to-report create-graph [current-graph current-process-as-list]
  ;; g1 and g2 are lists of processes that have been connected
  ;; it should hold true that if v is in g1 then v cannot be in g2
  let rand random-float 1
  let pf one-of current-graph
  let pt one-of current-process-as-list
  
  let connecting-channel-from 0
  
  ifelse (rand mod 2) = 0 [ set connecting-channel-from get-channel pf pt ]
                          [ set connecting-channel-from get-channel pt pf ]
  
  ;;let connecting-channel-from get-channel pf pt
  ;;let connecting-channel-to get-channel pt pf
              
  ask connecting-channel-from [ set active? true ]
  ;;ask connecting-channel-to   [ set active? true ]
  
  report lput first current-process-as-list current-graph
end

to create-connected-graph
  ;; every process has to have at-least two edges connected coming from it
  ;; this means at least for a graph G (V,E), where V represents the processes
  ;; and E represents the channels there will initially be |V| = population-size many processes
  ;; and |E| = |V| - 1 many channels
  
  ;; algorithm
  ;; remaining-processes -> a list of processes with no contacts
  ;; create a graph by connecting two random processes
  ;; while still remaining-processes
  ;;   select a random process from remaining-processes
  ;;   connect the current graph with the randomly selected process
  ;;   remove it from the remaining-processes
  ;; end while
  ;; update the processes succ, mailbox and contacts-list
  
  let remaining-processes [self] of processes
  
  let primary-one one-of remaining-processes
  set remaining-processes remove primary-one remaining-processes
  
  let primary-two one-of remaining-processes
  set remaining-processes remove primary-two remaining-processes
  
  let graph create-graph (list primary-one) (list primary-two)
  
  while [ not empty? remaining-processes ] [
    let current-process one-of remaining-processes
    set graph create-graph graph (list current-process)
    set remaining-processes remove current-process remaining-processes
  ]
  
  foreach [self] of channels with [ active? = true ] [
    ask [port-from] of ? [
      set succ lput [port-to] of ? succ
      set contacts-list succ
      set mailbox create-mailbox
      set super-mailbox create-super-mailbox
    ]
  ]
  
  ask processes [ 
    if empty? mailbox [ set mailbox create-mailbox ]
    if empty? super-mailbox [ set super-mailbox create-super-mailbox ]
  ]
end

to-report get-mailbox-from-super-mailbox [V]
  ;; V is of the form [ID, M, leader?], where M is the mailbox
  report first but-first V
end

to-report create-super-mailbox
  report (list (list ID mailbox is-leader?))
end

to-report create-mailbox
  report (list (list ID succ))
end

to-report create-message [connecting-channel]
  ifelse electing-leader? [ report (list (Time * [current-distance] of connecting-channel) (list ID super-mailbox)) ]
                          [ report (list (Time * [current-distance] of connecting-channel) (list ID mailbox)) ]
end

to-report union [list1 list2]
  if empty? list1 [ report list2 ]
  if empty? list2 [ report list1 ]
  let intersect intersection list1 list2
  let not-intersect2 filter [ not member? ? intersect ] list2
  let not-intersect1 filter [ not member? ? intersect ] list1
  report sentence sentence not-intersect1 not-intersect2 intersect
end

to-report intersection [list1 list2]
  report filter [ member? ? list1 ] list2
end

to-report difference [list1 list2]
  ;; list1 intersect list2 compliment
  ;; every element that is in list1 and NOT in list2
  let intersect intersection list2 list1
  report filter [ not member? ? intersect ] list1
end

to-report get-channel [pf pt]
  report first [self] of channels with [ port-to = pt and port-from = pf ]
end

to-report Covered [some-mailbox]
  ;;{idv|(idv, Succv) ∈ M} all initial lists
  ;; seach the initial neighbours to see if their info is in my mailbox
  ;; if so added them to the covered-list
  ;; after checking the mailbox return the covered-list
  let covered-list []
  
  foreach [self] of processes [
    let current-neighbour ?
    let neighbour-id [ID] of current-neighbour
    let neighbour-succ [succ] of current-neighbour
    
    foreach some-mailbox [
      let some-id first ?
      let some-succ last ?
    
      if (neighbour-id = some-id and neighbour-succ = some-succ) [ set covered-list lput current-neighbour covered-list ]
    ]
  ]
  report covered-list
end

to-report get-process-with-id [some-id]
  report first [self] of processes with [ ID = some-id ]
end

to-report view-set [some-mailbox]
  let vset []
  let me self
  
  foreach some-mailbox [
    let some-id first ?
    let some-succ last ?
    
    if (member? me some-succ) [ set vset lput get-process-with-id some-id vset ]
  ]
  report vset
end

to-report is-channel-active? [pf pt]
  let is-active? false
  ask get-channel pf pt [
    if active? [set is-active? true]
  ]
  report is-active?
end

to-report c-of-m [some-mailbox]
  ;; reports a new graph C(M) = (Vc, Ec) such that Vc = view-set of some-mailbox
  ;; and Ec = edges already defined in the mailbox
  ;; since we store graphs differently, we will only give Vc as the return value of this function
  report View some-mailbox
end

to-report list-equal? [list1 list2]
  if empty? list1 and not empty? list2 [ report false ]
  if empty? list2 and not empty? list1 [ report false ]
  
  foreach list1 [
    if not member? ? list2 [ report false ]
  ]
  foreach list2 [
    if not member? ? list1 [ report false ]
  ]
  report true
end

to-report View [some-mailbox]
  report union view-set some-mailbox Covered some-mailbox
end

to-report assert [answer is]
  if answer = is [ report true ]
  report false
end

to-report get-lowest-id
  let local-view View mailbox
  set local-view remove self local-view
  if empty? local-view [ report -1 ]
  report min map [ [ID] of ? ] local-view
end

to-report ids-are-present
  let present? true
  foreach View mailbox [
    let v-id [ID] of ?
    let v-mailbox [mailbox] of ?
    let v-leader [is-leader?] of ?
    
    if not member? (list v-id v-mailbox v-leader) super-mailbox [ set present? false ]
  ]
  report present?
end

to-report calculate-distance [pf pt]
  let dist 0
  ask pf [
    set dist floor distance pt
  ]
  report dist
end

to-report message-count
  let msg-count 0
  foreach [self] of processes [
    set msg-count msg-count + length [message-queue] of ?
  ]
  report msg-count
end

to-report already-leader
  let leader? false
  foreach super-mailbox [
    if last ? = "leader" [ set leader? true ]  
  ]
  report leader?
end

to-report n-vertex-characteristic-function [some-mailbox]
  let unique-ids []
  foreach c-of-m some-mailbox [
    let some-id [ID] of ?
    if not member? some-id unique-ids [ set unique-ids lput some-id unique-ids ]
  ] 
  if length unique-ids = population-size [ report true ]
  report false
  ;;report list-equal? unique-ids selected-ids
end
@#$#@#$#@
GRAPHICS-WINDOW
200
10
753
584
16
16
16.455
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

SLIDER
21
10
188
43
population-size
population-size
2
100
2
1
1
NIL
HORIZONTAL

BUTTON
22
47
126
80
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
23
161
188
206
Active Channels
count channels with [ active? = true ]
17
1
11

BUTTON
132
47
188
80
Go
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
22
86
126
119
Run Tests
run-tests
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
23
124
188
157
electing-leader?
electing-leader?
0
1
-1000

BUTTON
132
87
187
120
Clear
clear
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
23
261
188
294
Time
Time
0
5
0
1
1
NIL
HORIZONTAL

PLOT
773
35
1067
248
Messages Vs. Time
Time
# of Messages
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot number-of-messages"

MONITOR
23
212
188
257
Message Count
number-of-messages
17
1
11

BUTTON
23
299
188
332
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
24
336
187
381
Total Messages
total-messages
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
