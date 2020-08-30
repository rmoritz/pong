#!/usr/bin/env bash

tmpx -i src/pong.asm -o dist/pong.prg -l src/list.txt && \
mkd64 -o dist/pong.d64 -m cbmdos -d 'PONG' -m separators \
-f dist/pong.prg -n PONG -w
