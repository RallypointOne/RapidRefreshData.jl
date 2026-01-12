module RapidRefreshData

using Dates, Scratch

const rap_base_url = "https://noaa-rap-pds.s3.amazonaws.com/rap."
const gfs_base_url = "https://noaa-gfs-bdp-pds.s3.amazonaws.com/gfs"
const hrrr_base_url = "https://noaa-hrrr-bdp-pds.s3.amazonaws.com/hrrr"


#-----------------------------------------------------------------------------# __init__
rap_dir::String = ""
gfs_dir::String = ""
hrrr_dir::String = ""

function __init__()
    global rap_dir = Scratch.@get_scratch!("rap")
    global gfs_dir = Scratch.@get_scratch!("gfs")
    global hrrr_dir = Scratch.@get_scratch!("hrrr")
end

#-----------------------------------------------------------------------------# RAPDataset
"""
    RAPDataset(; date, cycle_time, grid, product, forecast)

NOAA Rapid Refresh (RAP) dataset descriptor.

# Fields
- `date::Date`: Forecast initialization date (default: today)
- `cycle_time::String`: Model run time - "t00z", "t06z", "t12z", or "t18z" (default: "t00z")
- `grid::String`: Grid resolution - "awp130" (~13km) or "awp252" (~32km) (default: "awp130")
- `product::String`: Data type - "pgrb" (pressure), "sfcbf" (surface), or "isobf" (isentropic) (default: "pgrb")
- `forecast::String`: Forecast hour - "f00" to "f18" (default: "f00")
"""
@kwdef struct RAPDataset
    date::Date = today()
    cycle_time::String = "t00z"
    grid::String = "awp130"
    product::String = "pgrb"
    forecast::String = "f00"  # "f00" to "f18"
end

function Base.show(io::IO, dset::RAPDataset)
    (;date, cycle_time, grid, product, forecast) = dset
    print(io, "RAPDataset", (; date=string(date), cycle_time, grid, product, forecast))
end

function Base.read(::Type{RAPDataset}, local_path::String)
    filename = split(basename(local_path), ".")[1]
    parts = split(filename, "_")
    # Skip "rap" prefix (parts[1]) and parse remaining parts
    date = Date(parts[2], "yyyymmdd")
    cycle_time = parts[3]
    grid = parts[4]
    forecast = parts[5]
    return RAPDataset(; date, cycle_time, grid, forecast)
end

"""
    url(dset::RAPDataset) -> String

Generate AWS S3 URL for the RAP dataset.
"""
function url(dset::RAPDataset)
    "$rap_base_url$(Dates.format(dset.date, "yyyymmdd"))/rap.$(dset.cycle_time).$(dset.grid)pgrb$(dset.forecast).grib2"
end

"""
    local_path(dset::RAPDataset) -> String

Get local cache path for the RAP dataset.
"""
function local_path(dset::RAPDataset)
    joinpath(rap_dir, "rap_$(Dates.format(dset.date, "yyyymmdd"))_$(dset.cycle_time)_$(dset.grid)_$(dset.forecast).grib2")
end

"""
    get(dset::RAPDataset) -> String

Download RAP dataset to cache (if needed) and return filepath.
"""
function Base.get(dset::RAPDataset)
    isfile(local_path(dset)) ? local_path(dset) : Base.download(url(dset), local_path(dset))
end

"""
    local_datasets(RAPDataset) -> Vector{RAPDataset}

List all cached RAP datasets.
"""
function local_datasets(::Type{RAPDataset})
    read.(RAPDataset, readdir(rap_dir))
end

"""
    clear_local_dataset!(dset::RAPDataset)

Remove RAP dataset from local cache.
"""
function clear_local_dataset!(dset::RAPDataset)
    isfile(local_path(dset)) && rm(local_path(dset))
end

#-----------------------------------------------------------------------------# GFSDataset
"""
    GFSDataset(; date, cycle, resolution, product, forecast)

NOAA Global Forecast System (GFS) dataset descriptor.

# Fields
- `date::Date`: Forecast initialization date (default: today)
- `cycle::String`: Model run time - "00", "06", "12", or "18" (default: "00")
- `resolution::String`: Grid resolution - "0p25" (0.25°), "0p50" (0.50°), or "1p00" (1.00°) (default: "0p25")
- `product::String`: Product type - "atmos" or "wave" (default: "atmos")
- `forecast::String`: Forecast hour - "f000" to "f384" (default: "f000")
"""
@kwdef struct GFSDataset
    date::Date = today()
    cycle::String = "00"  # "00", "06", "12", "18"
    resolution::String = "0p25"  # "0p25", "0p50", "1p00"
    product::String = "atmos"  # "atmos", "wave"
    forecast::String = "f000"  # "f000" to "f384"
end

function Base.show(io::IO, dset::GFSDataset)
    (;date, cycle, resolution, product, forecast) = dset
    print(io, "GFSDataset", (; date=string(date), cycle, resolution, product, forecast))
end

function Base.read(::Type{GFSDataset}, local_path::String)
    filename = split(basename(local_path), ".")[1]
    parts = split(filename, "_")
    # Skip "gfs" prefix (parts[1]) and parse remaining parts
    date = Date(parts[2], "yyyymmdd")
    cycle = parts[3]
    resolution = parts[4]
    product = parts[5]
    forecast = parts[6]
    return GFSDataset(; date, cycle, resolution, product, forecast)
end

"""
    url(dset::GFSDataset) -> String

Generate AWS S3 URL for the GFS dataset.
"""
function url(dset::GFSDataset)
    "$(gfs_base_url).$(Dates.format(dset.date, "yyyymmdd"))/$(dset.cycle)/$(dset.product)/gfs.t$(dset.cycle)z.pgrb2.$(dset.resolution).$(dset.forecast)"
end

"""
    local_path(dset::GFSDataset) -> String

Get local cache path for the GFS dataset.
"""
function local_path(dset::GFSDataset)
    joinpath(gfs_dir, "gfs_$(Dates.format(dset.date, "yyyymmdd"))_$(dset.cycle)_$(dset.resolution)_$(dset.product)_$(dset.forecast).grib2")
end

"""
    get(dset::GFSDataset) -> String

Download GFS dataset to cache (if needed) and return filepath.
"""
function Base.get(dset::GFSDataset)
    isfile(local_path(dset)) ? local_path(dset) : Base.download(url(dset), local_path(dset))
end

"""
    local_datasets(GFSDataset) -> Vector{GFSDataset}

List all cached GFS datasets.
"""
function local_datasets(::Type{GFSDataset})
    read.(GFSDataset, readdir(gfs_dir))
end

"""
    clear_local_dataset!(dset::GFSDataset)

Remove GFS dataset from local cache.
"""
function clear_local_dataset!(dset::GFSDataset)
    isfile(local_path(dset)) && rm(local_path(dset))
end

#-----------------------------------------------------------------------------# HRRRDataset
"""
    HRRRDataset(; date, cycle, region, product, forecast)

NOAA High-Resolution Rapid Refresh (HRRR) dataset descriptor.

# Fields
- `date::Date`: Forecast initialization date (default: today)
- `cycle::String`: Model run hour - "00" to "23" (default: "00")
- `region::String`: Geographic region - "conus" (Continental US) or "alaska" (default: "conus")
- `product::String`: Product type - "wrfsfc" (surface), "wrfprs" (pressure), "wrfnat" (native), or "wrfsub" (subhourly) (default: "wrfsfc")
- `forecast::String`: Forecast hour - "f00" to "f48" (default: "f00")
"""
@kwdef struct HRRRDataset
    date::Date = today()
    cycle::String = "00"  # "00" to "23"
    region::String = "conus"  # "conus", "alaska"
    product::String = "wrfsfc"  # "wrfsfc", "wrfprs", "wrfnat", "wrfsub"
    forecast::String = "f00"  # "f00" to "f48"
end

function Base.show(io::IO, dset::HRRRDataset)
    (;date, cycle, region, product, forecast) = dset
    print(io, "HRRRDataset", (; date=string(date), cycle, region, product, forecast))
end

function Base.read(::Type{HRRRDataset}, local_path::String)
    filename = split(basename(local_path), ".")[1]
    parts = split(filename, "_")
    # Skip "hrrr" prefix (parts[1]) and parse remaining parts
    date = Date(parts[2], "yyyymmdd")
    cycle = parts[3]
    region = parts[4]
    product = parts[5]
    forecast = parts[6]
    return HRRRDataset(; date, cycle, region, product, forecast)
end

"""
    url(dset::HRRRDataset) -> String

Generate AWS S3 URL for the HRRR dataset.
"""
function url(dset::HRRRDataset)
    "$(hrrr_base_url).$(Dates.format(dset.date, "yyyymmdd"))/$(dset.region)/hrrr.t$(dset.cycle)z.$(dset.product)$(dset.forecast).grib2"
end

"""
    local_path(dset::HRRRDataset) -> String

Get local cache path for the HRRR dataset.
"""
function local_path(dset::HRRRDataset)
    joinpath(hrrr_dir, "hrrr_$(Dates.format(dset.date, "yyyymmdd"))_$(dset.cycle)_$(dset.region)_$(dset.product)_$(dset.forecast).grib2")
end

"""
    get(dset::HRRRDataset) -> String

Download HRRR dataset to cache (if needed) and return filepath.
"""
function Base.get(dset::HRRRDataset)
    isfile(local_path(dset)) ? local_path(dset) : Base.download(url(dset), local_path(dset))
end

"""
    local_datasets(HRRRDataset) -> Vector{HRRRDataset}

List all cached HRRR datasets.
"""
function local_datasets(::Type{HRRRDataset})
    read.(HRRRDataset, readdir(hrrr_dir))
end

"""
    clear_local_dataset!(dset::HRRRDataset)

Remove HRRR dataset from local cache.
"""
function clear_local_dataset!(dset::HRRRDataset)
    isfile(local_path(dset)) && rm(local_path(dset))
end


end
