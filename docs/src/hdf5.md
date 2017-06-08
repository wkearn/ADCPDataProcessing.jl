# HDF5 Support

```@meta
CurrentModule = ADCPDataProcessing
```

## HDF5 Schema

The HDF5 file produced by [`database2HDF5`](@ref) follows the following schema

- `data.h5` -- This is the HDF5 file. Each site has a different HDF5 file, but they are all called `data.h5`
  - `gps` -- This **group** contains information on the location of the site stored as attributes
      - `epsg` -- This **attribute** gives the EPSG code for the projection in which the coordinates are stored
      - `east` -- This **attribute** gives the coordinate in the east direction
      - `north` -- This **attribute** gives the coordinate in the north direction
  - `cross-section` -- This **group** contains the channel cross section of the site
      - `epsg` -- This **attribute** gives the EPSG code for the projection in which the GPS cross section is stored
      - `north` -- This **dataset** is an array with the north coordinates for the points making up the cross section
      - `east` -- This **dataset** is an array with the east coordinates for the points making up the cross section
      - `elevation` -- This **dataset** gives the elevation of the points making up the cross section
      - `distance` -- This **dataset** gives the distance along the cross section from an arbitrary starting point
  - `deployments` -- This **group** contains each of the ADCP deployments at the site
    - `$id` -- This **group** contains all of the data and metadata for a single deployment. `$id` is a random code used to identify the deployment
        - `serialNumber` -- This **attribute** is the serial number of the ADCP used in this deployment
        - `startDate` -- This **attribute** is the start date/time of the deployment
        - `endDate` -- This **attribute** is the end date/time of the deployment
        - `deltaT` -- This **attribute** is the sampling period in seconds
        - `blankingDistance` -- This **attribute** is the blanking distance above the ADCP in meters
        - `cellSize` -- This **attribute** is the size of each measurement cell in meters
        - `nCells` -- This **attribute** is the number of measurement cells recorded by the ADCP
        - `elevation` -- This **attribute** is the elevation at which the ADCP is deployed, in the frame of the cross section
        - `hasAnalog` -- This **attribute** indicates whether an analog input was attached to the ADCP
        - `obsSerialNumber` -- This **optional attribute** is the serial number of the OBS sensor deployed with the ADCP. It exists only if `hasAnalog==true`
        - `validAnalog` -- This **optional attribute** indicates whether the analog input data are usable. It exists only if `hasAnalog==true`
        - `amplitude` -- This **dataset** is an (`nCells`,`N`,3) array giving the return signal amplitudes in counts
        - `heading` -- This **dataset** is an array of length `N` giving the heading recorded by the internal compass of the ADCP in degrees
        - `pitch` -- This **dataset** is an array of length `N` giving the pitch about the short horizontal axis of the ADCP in degrees
        - `roll` -- This **dataset** is an array of length `N` giving the roll about the long horizontal axis of the ADCP in degrees
        - `pressure` -- This **dataset** is an array of length `N` giving the pressure recorded by the internal pressure sensor in dbar
        - `temperature` -- This **dataset** is an array of length `N` giving the temperature in degrees C
        - `time` -- This **dataset** is an array of length `N` of strings giving the date and time of each measurement
        - `velocity` -- This **dataset** is an array of size (`nCells`,`N`,3) giving the water column velocities in m/s
        - `analog1` -- This **optional dataset** is an array of length `N` giving the signal recorded at analog input #1 in mV. It exists if `hasAnalog==true`
        - `analog2` -- This **optional dataset** is an array of length `N` giving the signal recorded at analog input #2 in mV. It exists if `hasAnalog==true`
  - `calibrations`
    - `startDate` -- This **attribute** gives the start date of the calibration
    - `endDate` -- This **attribute** gives the end date of the calibration
    - `deployment` -- This **attribute** gives the id of the ADCP deployment during which the calibration took place
    - `discharge` -- This **dataset** provides the discharges measured by the calibrating instrument in m^3/s
    - `discharge_times` -- This **dataset** provides the dates and times at which the calibrating instrument recorded discharges
    - `tss` -- This **optional dataset** provides the TSS measurements in g/L
    - `tss_times` -- This **optional dataset** provides the dates ans times at which the TSS was measured.


# Functions for dealing with the HDF5 database


```@docs
database2HDF5
```
