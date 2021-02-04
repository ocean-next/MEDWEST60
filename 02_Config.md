


# The MEDWEST60 Configuration 


## Code source
The code source is available [[Here](./src_config/)]

### Motivation
A strong basis for the present work is the already-existing kilometric-scale simulation eNATL60 performed by Ocean Next and IGE recently over the North Atlantic area ([Bordeau et al 2020](http://doi.org/10.5281/zenodo.4032732)): [https://github.com/ocean-next/eNATL60](https://github.com/ocean-next/eNATL60). 

This simulation was designed  to model as accurately as possible the surface signature of oceanic motions of scales down to 15km, which is, for example, the expected resolution of   the future altimetry mission  SWOT (Surface Ocean and Water Topography, [Fu and Ferrari 2008](https://doi.org/10.1029/2008EO480003), [Durand et al 2010](https://doi.org/10.1109/JPROC.2010.2043031) ). It  provides a unique scientific material at this resolution to  study fine-scale processes (<200 km) and cross-scale interactions  in the ocean, from submesoscale processes  to basin-scale features.  The cost in CPU, memory and storage for such a simulation is however too high to consider performing  several sets of ensemble experiments over the entire North Atlantic  domain. Instead, we designed here a new regional configuration, following  as much as possible the eNATL60 setup, but covering a smaller area, and we use the eNATL60 simulation for hourly boundary conditions. 

### The regional domain
![plot](https://github.com/ocean-next/MEDWEST60/blob/master/figs/MEDWEST60_bathy.png)<br>
*Figure 1: Domain and bathymetry (in km) of the MEDWEST60 regional configuration.*

The targeted region was  selected over the Western Mediterranean Sea, as this area is  included in the eNATL60  domain, and minimizes the length of the open lateral boundaries given the  geography of the basin (the western lateral boundary is set at the Gibraltar Strait, and the eastern lateral boundary along a line going from north to south through Corsica and Sardinia, see Figure 1. The full domain covers 1200 km x 1100 km, from  35.1ºN  to  44.4ºN in latitude and from  5.7ºW to 9.5ºE in longitude. 

The MEDWEST60  configuration includes tides and is forced at the western and eastern boundaries with hourly outputs from the reference simulation eNATL60-with-tides (i.e. "eNATL60-TCLB02" in the eNATL60 nomenclature).
By design, all technical and parameter choices  for the regional configuration MEDWEST60 were made with the idea to remain as close as possible from the reference simulation eNATL60-LBT02. In particular, we use strictly the same horizontal and  vertical grids as the reference simulation, meaning that there is no need for spatial interpolation of the  lateral boundary conditions from the reference simulation. 

Domain and bathymetry (in km) of the MEDWEST60 regional configuration. The full domain covers 883 x 803 grid points in the horizontal, representing 1200 km x 1100 km, from  35.1ºN  to  44.4ºN in latitude and from  5.7ºW to 9.5ºE in longitude. The two yellow boxes show the subregions over which  spectral analysis is performed (dotted line) in the following, and over which zoomed snapshots will be plotted (solid line).


#### MEDWEST60 specifications:
- Numerical code: NEMO 3.6 + XIOS-2.0 (\url{https://www.nemo-ocean.eu/})
-  Horizontal resolution: 1/60º, 
-  Grid size:  883 x 803 in the horizontal (1.20 km <$\Delta\mathrm{x}$<1.55 km),
-  Vertical grid: 212 levels along the vertical, those levels are defined exactly as in eNATL60-LBT02 but only 212 levels  are actually needed to include the deepest points in the Western Mediterranean region (i.e 3217 m at the deepest), while 300 levels were used in eNATL60 to cover the depth range in the North Atlantic basin. The  following discretisation is applied to the  first 20 meters below the surface: 0.48 m, 1.56 m, 2.79 m, 4.19 m, 5.74 m, 7.45 m, 9.32 m, 11.35 m,  13.54 m, 15.89 m, 18.40 m, 21.07 m.
-  Atmospheric forcing: 3-hourly ERA-interim (ECMWF),
-  Lateral boundary conditions at the coast: no slip,
-  Lateral boundary conditions: hourly outputs from the reference simulation eNATL60-TCLB02 (which explicitly includes tides). The Flow Relaxation Scheme ("frs") is used for baroclinic velocities and active tracers (simple relaxation of the model fields to externally-specified values over a 12 grid point zone next to the edge of the model domain). The "Flather"  radiation scheme is used for sea-surface height and barotropic velocities (a radiation condition is applied on the normal depth-mean transport across the open boundary).

Doing so, we are able to start the MEDWEST60 regional configuration directly from initial conditions stored from eNATL60-LBT02  (i.e. from  NEMO restart files) without the need for a  spinup of several months/years as when starting from climatological conditions.

In summary, the only  differences between MEDWEST60 and eNATL60-LB02 are:
- the smaller regional domain,
- the lateral boundary conditions,
- there is no  additional tidal harmonic forcing at the lateral boundaries in MEDWEST60 since the tidal forcing is already explicitly part of the hourly boundary forcing from eNATL60 outputs, 
- the model time-step has been   increased  by a factor 2  ( 80 seconds in MEDWEST60 versus 40 seconds in eNATL60) in this regional domain (stability criteria easier to meet in the West Mediterranean region compared to other regions in the North Atlantic). 

## Starting protocole  (spinup) and time-step change:



