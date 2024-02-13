# we_maze

a command to create a 2D maze using worldedit.

uses wilson's algorithm.

you can specify material(s), path width, wall width, and a seed.

e.g.
```
//maze default:stone,default:cobble air 3 2 7717
```

makes a maze where the nodes in the walls are randomly cobble or stone, the passsages are air, the width of a path is
3, the width of the walls is 2, and 7717 is a seed (to generate the same maze consistently). note that if a seed is
provided, the maze will only be identical if the x/z size is identical.
