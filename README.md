# RapidRefreshData

[![Build Status](https://github.com/RallypointOne/RapidRefreshData.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/RallypointOne/RapidRefreshData.jl/actions/workflows/CI.yml?query=branch%3Amain)

This package provides easy access of NOAA's Rapid Refresh (RAP) data ([https://rapidrefresh.noaa.gov](https://rapidrefresh.noaa.gov)) hosted on AWS.  Data will be saved to your scratchspace.

# Usage

```julia
using RapidRefreshData: Dataset
using Rasters, ArchGDAL

data = Dataset()

filepath = get(data)

r = Raster(filepath; checkmem=false)
```

# `Dataset`

```julia
@kwdef struct Dataset
    date::Date = today()
    cycle_time::String = "t00z"
    grid::String = "awp130"   # ~13km horizontal resolution
    product::String = "pgrb"  # pgrb (Pressure Levels), sfcbf (Surface Fields), isobf (Isentropic)
    forecast::String = "f00"  # "f00" to "f18"
end
```


