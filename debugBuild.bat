@echo off

if not exist .\\build mkdir .\\build
odin build . -debug -out:build/debug.exe