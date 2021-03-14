# C167 Boost PID

## Description
Custom boost PID controller implementation targeted for use in Bosch ME7 control units for N/A engines with aftermarket turbo installs.

## Features
- 3D Precontrol map
- Setpoint map per gear
- Steady state and Dynamic modes
- Operation windowing for on/off
- Runs from pssol_w as setpoint and ps_w as actual measurement, compatible with MAF or MAP
- Application mode for calibrating precontrol - open loop duty per RPM

## Installation
The main function should be placed into a scheduled task, that gets run not less than every 20ms.  
The frequency at which the PID is executed basically defines the scale of the units in the P, I and D maps.  
You need to re-configure a PWM output. Usually on ME7 with a boosted engine PW1 is the N75 output, on N/A they use that output for the manifold changeover flap, see the example file on how to do this.  
Any native output writes to the PWM need to be disabled also (CC 00).  

## Description of parameters from asm
fixdcmap - Fixed DC map for application mode  
fixdcflag - When set to 1 the PID is turned off and fixdcmap values are output directly  
pilotmap - Pre-control DC map based on RPM and pssol_w. If you are going to be using it at significant elevation changes, it is a good idea to subtract pu_w from pssol_w when reading this map.  
dcmax - maximum allowed PWM  
dcmin - minimum allowed PWM  
piden - minimum pssol_w for enabling PID, should be at around spring cracking pressure  
imaxthres - threshold lderr to switch from dynamic (P/D mode) to steady state (PID mode)  
pidpmap - P-term  
pidimap - I-term  
piddmap - D-term  
ldrxn - requested load based on RPM and gear  
