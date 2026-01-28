# RapidRefreshData

[![Build Status](https://github.com/RallypointOne/RapidRefreshData.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/RallypointOne/RapidRefreshData.jl/actions/workflows/CI.yml?query=branch%3Amain)

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

## Dataset Types

### HRRRDataset (High-Resolution Rapid Refresh)

3km resolution US weather model with hourly updates.

| Field | Options | Description |
|-------|---------|-------------|
| `date` | `Date` | Forecast initialization date |
| `cycle` | `"00"` to `"23"` | Model run hour (hourly) |
| `region` | `"conus"`, `"alaska"` | Geographic region |
| `product` | `"wrfsfc"`, `"wrfprs"`, `"wrfnat"`, `"wrfsub"` | Surface, pressure, native, or subhourly |
| `forecast` | `"f00"` to `"f48"` | Forecast hour |

### RAPDataset (Rapid Refresh)

Continental US weather model with 6-hour update cycles.

| Field | Options | Resolution |
|-------|---------|------------|
| `grid` | `"awp130"` | ~13 km |
| `grid` | `"awp252"` | ~32 km |

| Field | Options | Description |
|-------|---------|-------------|
| `date` | `Date` | Forecast initialization date |
| `cycle` | `"t00z"`, `"t06z"`, `"t12z"`, `"t18z"` | Model run time (6-hourly) |
| `grid` | `"awp130"`, `"awp252"` | Grid resolution |
| `product` | `"pgrb"`, `"sfcbf"`, `"isobf"` | Pressure, surface, or isentropic |
| `forecast` | `"f00"` to `"f18"` | Forecast hour |

### GFSDataset (Global Forecast System)

Global weather model with 6-hour update cycles.

| Field | Options | Resolution |
|-------|---------|------------|
| `resolution` | `"0p25"` | ~28 km |
| `resolution` | `"0p50"` | ~56 km |
| `resolution` | `"1p00"` | ~111 km |

| Field | Options | Description |
|-------|---------|-------------|
| `date` | `Date` | Forecast initialization date |
| `cycle` | `"00"`, `"06"`, `"12"`, `"18"` | Model run time (6-hourly) |
| `resolution` | `"0p25"`, `"0p50"`, `"1p00"` | Grid resolution in degrees |
| `product` | `"atmos"`, `"wave"` | Atmospheric or wave |
| `forecast` | `"f000"` to `"f384"` | Forecast hour |
