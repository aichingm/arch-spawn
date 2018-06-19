#!/bin/bash
if [ -f var/$i ]; then cat var/$1; else cat const/$1; fi
