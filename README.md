# RapidRefreshData

[![Build Status](https://github.com/RallypointOne/RapidRefreshData.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/RallypointOne/RapidRefreshData.jl/actions/workflows/CI.yml?query=branch%3Amain)

Easy access to NOAA weather model data from AWS:
- **RAP (Rapid Refresh)** - Regional high-resolution forecasts ([rapidrefresh.noaa.gov](https://rapidrefresh.noaa.gov))
- **GFS (Global Forecast System)** - Global forecasts

Data is automatically downloaded and cached in your scratchspace.

## Installation

```julia
using Pkg
Pkg.add("RapidRefreshData")
```

## Quick Start

### RAP Data

```julia
using RapidRefreshData
using Dates

# Create a RAP dataset
rap = RAPDataset(
    date = Date(2025, 1, 8),
    cycle_time = "t12z",
    forecast = "f06"
)

# Download (or get cached path)
filepath = get(rap)

# Use with Rasters.jl
using Rasters
r = Raster(filepath; checkmem=false)
```

### GFS Data

```julia
using RapidRefreshData
using Dates

# Create a GFS dataset
gfs = GFSDataset(
    date = Date(2025, 1, 8),
    cycle = "12",
    resolution = "0p25",  # 0.25° resolution
    forecast = "f006"
)

# Download (or get cached path)
filepath = get(gfs)
```

## Dataset Types

### `RAPDataset`

```julia
@kwdef struct RAPDataset
    date::Date = today()
    cycle_time::String = "t00z"      # "t00z", "t06z", "t12z", "t18z"
    grid::String = "awp130"          # awp130 (~13km), awp252 (~32km)
    product::String = "pgrb"         # pgrb (Pressure), sfcbf (Surface), isobf (Isentropic)
    forecast::String = "f00"         # "f00" to "f18" (hourly)
end
```

### `GFSDataset`

```julia
@kwdef struct GFSDataset
    date::Date = today()
    cycle::String = "00"             # "00", "06", "12", "18"
    resolution::String = "0p25"      # "0p25" (0.25°), "0p50" (0.50°), "1p00" (1.00°)
    product::String = "atmos"        # "atmos", "wave"
    forecast::String = "f000"        # "f000" to "f384"
end
```

## API Functions

### Download/Access
- `get(dataset)` - Download dataset or return cached filepath

### List Local Data
- `local_datasets(RAPDataset)` - List all cached RAP datasets
- `local_datasets(GFSDataset)` - List all cached GFS datasets

### Clear Cache
- `clear_local_dataset!(dataset)` - Remove a specific dataset from cache

### Generate URLs/Paths
- `url(dataset)` - Get AWS S3 URL for dataset
- `local_path(dataset)` - Get local cache path for dataset

## Examples

### List and clean up local datasets

```julia
# List all RAP datasets
rap_datasets = local_datasets(RAPDataset)

# Clear old datasets
for dset in rap_datasets
    if dset.date < today() - Day(7)
        clear_local_dataset!(dset)
    end
end
```

### Download multiple forecast hours

```julia
using Dates

date = Date(2025, 1, 8)
cycle = "12"

# Download GFS forecasts for 0, 6, 12, 18 hours
for fhour in 0:6:18
    gfs = GFSDataset(
        date = date,
        cycle = cycle,
        forecast = string("f", lpad(fhour, 3, '0'))
    )
    filepath = get(gfs)
    println("Downloaded: ", basename(filepath))
end
```


