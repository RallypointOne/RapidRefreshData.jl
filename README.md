[![CI](https://github.com/RallypointOne/RapidRefreshData.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/RallypointOne/RapidRefreshData.jl/actions/workflows/CI.yml)
[![Docs Build](https://github.com/RallypointOne/RapidRefreshData.jl/actions/workflows/Docs.yml/badge.svg)](https://github.com/RallypointOne/RapidRefreshData.jl/actions/workflows/Docs.yml)
[![Stable Docs](https://img.shields.io/badge/docs-stable-blue)](https://RallypointOne.github.io/RapidRefreshData.jl/stable/)
[![Dev Docs](https://img.shields.io/badge/docs-dev-blue)](https://RallypointOne.github.io/RapidRefreshData.jl/dev/)

# RapidRefreshData.jl

Easy access to NOAA weather model data from AWS:
- **HRRR (High-Resolution Rapid Refresh)** - 3km resolution, hourly updates
- **RAP (Rapid Refresh)** - 13km resolution, 6-hour cycles
- **GFS (Global Forecast System)** - Global forecasts, 0.25° resolution

Data is automatically downloaded and cached locally in your scratchspace.

## Installation

```julia
using Pkg
Pkg.add("RapidRefreshData")
```

## Quick Start

```julia
using RapidRefreshData, Dates

# Create a dataset descriptor
dset = HRRRDataset(
    date = Date(2024, 1, 15),
    cycle = "12",
    forecast = "f06"
)

# Download full file
path = get(dset)

# Or download only specific variables
all_bands = bands(dset)
wind_bands = filter(b -> b.variable in ["UGRD", "VGRD"], all_bands)
path = get(dset, wind_bands)
```
