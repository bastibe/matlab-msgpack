# A MessagePack implementation for Matlab

The code is written in pure Matlab, and has no dependencies beyond Matlab itself. It does not work in Octave, since Octave does not support `unicode2native` or `native2unicode`.

The files in this repository are taken from [Transplant](https://github.com/bastibe/transplant).

## Basic Usage:
```matlab
data = {'life, the universe, and everything', struct('the_answer', 42)};
bytes = dumpmsgpack(data)
data = parsemsgpack(bytes)
% returns: {'life, the universe, and everything', containers.Map('the_answer', 42)}
```

## Converting Matlab to MsgPack:

| Matlab         | MsgPack                   |
| -------------- | ------------------------- |
| string         | string                    |
| scalar         | number                    |
| logical        | `true`/`false`            |
| vector         | array of numbers          |
| uint8 vector   | bin                       |
| matrix         | array of array of numbers |
| empty matrix   | nil                       |
| cell array     | array                     |
| cell matrix    | array of arrays           |
| struct         | map                       |
| containers.Map | map                       |
| struct array   | array of maps             |
| handles        | raise error               |

There is no way of encoding exts

## Converting MsgPack to Matlab

| MsgPack        | Matlab         |
| -------------- | -------------- |
| string         | string         |
| number         | scalar         |
| `true`/`false` | logical        |
| nil            | empty matrix   |
| array          | cell array     |
| map            | containers.Map |
| bin            | uint8          |
| ext            | uint8          |

Note that since `structs` don't support arbitrary field names, they can't be used for representing `maps`. We use `containers.Map` instead.

## Tests
 ```matlab
 runtests()
 ```
