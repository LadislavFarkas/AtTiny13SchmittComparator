# AtTiny13SchmittComparator
PB0 - output

PB1 - negative output

PB2 - input analog signal

PB4 - upper threshold value

PB3 - lower threshold value


For all inputs : minimal value is GND, and maximal value is VCC.

Schmitt comparator is defined with threshold values on pin PB3 (lower thr.), and PB4 (upper thr.).

Output pin PB0 is switch to the H, when value on input pin PB2 are higher than threshold on pin PB4.

Output pin PB0 is return to the L, when is value in input pin PB2 lower than threshold on pin PB3.

Output pin PB1 has always opposite value like pin PB0.
