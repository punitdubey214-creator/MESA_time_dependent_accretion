# MESA_time_dependent_accretion
# Time-Dependent Accretion in MESA (Nova Simulations)

This repository contains custom implementations of time-dependent accretion built on the standard MESA test suite case `wd_nova_burst`, developed as part of an M.Sc. thesis on nuclear burning on accreting white dwarfs.

The goal is to study how variable accretion affects thermonuclear runaway (TNR), recurrence time, and mass growth.

---
## Acknowledgment

This work builds upon the open-source MESA stellar evolution code and its test suite.

## Repository Structure

```
MESA_time_dependent_accretion/
│
├── function_implementation/
│   └── run_star_extras.f90
│
├── csv_implementation/
│   └── run_star_extras.f90
│
└── README.md
```

## Overview

Two approaches for time-dependent accretion are implemented:

### 1. Function-Based Accretion
- Accretion rate defined analytically as a function of time
- Constant accretion initially, followed by sinusoidal variation
- Useful for controlled experiments

### 2. CSV-Based Accretion
- Accretion rate read from an external file
- Interpolated in time
- Used to model disc-instability driven accretion

---

## How to Use (with MESA)

Start from the standard MESA test suite:
wd_nova_burst


---

### Step 1: Replace `run_star_extras`

Replace the default file with:


function_implementation/run_star_extras.f90


or


csv_implementation/run_star_extras.f90


Then recompile:


./mk


---

### Step 2: Modify Inlist

Make the following changes in the default `wd_nova_burst` inlist:

#### Disable constant accretion

mass_change = 0


#### Enable custom control flag

x_logical_ctrl(1) = .true.


#### Ensure custom termination is used

required_termination_code_string = 'extras_check_model'




## Accretion Implementation

## Function-Based Model

The accretion rate is defined as:

- Constant for early times  
- Sinusoidal variation after a transition time  

```
mdot(t) = mdot_max                          for t < t_switch
mdot(t) = mdot_mean + mdot_amp * sin(2π (t - t_switch)/P)   for t ≥ t_switch
```

Typical parameters:
- P = 1 year  
- t_switch = 100 years

### CSV-Based Model

- Accretion rate is read from a file
- Interpolated in time
- Can represent realistic disc-instability profiles

Note: Users must provide their own CSV file and update the file path in `run_star_extras.f90`.

---

## Simulation Control

- Accretion is applied through:

s% mass_change


- Controlled inside:

extras_finish_step


- Termination condition is defined in:

extras_check_model


---

## Notes

- This repository provides the core implementation only
- Full inlists and data files are not included
- Simulations should be built from the MESA test case `wd_nova_burst`

---

## Requirements

- MESA (recent version)
- Fortran compiler (e.g. gfortran)

---

## Author

Punit Dubey  
M.Sc. Physics  
NIT Rourkela
