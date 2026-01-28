module RapidRefreshData

using Dates, Scratch, Downloads

export AbstractDataset, RAPDataset, GFSDataset, HRRRDataset
export Band, bands, index_url
export url, local_path, nextcycle, list, clear_cache!!, resolution_km, metadata, datasets

#-----------------------------------------------------------------------------# __init__
"scratch directory for caching downloaded datasets"
DIR::String = ""

function __init__()
    global DIR = Scratch.@get_scratch!("cache")
end

#-----------------------------------------------------------------------------# AbstractDataset
abstract type AbstractDataset end
# Required: url(::AbstractDataset)::String

"""
    local_path(dset::AbstractDataset) -> String

Generate local cache path for the dataset based on its parameters.
"""
function local_path(dset::T) where {T <: AbstractDataset}
    out = "data"
    for (k, v) in pairs(NamedTuple(dset))
        out *= "_"
        out *= v isa Date ? Dates.format(v, "yyyymmdd") : string(v)
    end
    return joinpath(dir(T), out * ".grib2")
end

dir(::Type{T}) where {T <: AbstractDataset} = mkpath(joinpath(DIR, string(T.name.name)))

function Base.NamedTuple(dset::T) where {T <: AbstractDataset}
    names = fieldnames(T)
    values = getfield.(Ref(dset), names)
    return NamedTuple{names}(values)
end

function Base.show(io::IO, dset::AbstractDataset)
    print(io, "$(typeof(dset))", Base.NamedTuple(dset))
end

function Base.get(dset::AbstractDataset)::String
    isfile(local_path(dset)) ? local_path(dset) : Base.download(url(dset), local_path(dset))
end

function Base.read(::Type{T}, local_path::String) where {T <: AbstractDataset}
    # Strip .grib2 extension and split by underscore
    filename = replace(basename(local_path), ".grib2" => "")
    parts = split(filename, "_")[2:end]  # Skip "data" prefix

    field_names = fieldnames(T)
    field_types = fieldtypes(T)
    field_values = Any[]
    for (i, (name, type)) in enumerate(zip(field_names, field_types))
        if name == :date
            push!(field_values, Date(parts[i], "yyyymmdd"))
        elseif type <: Integer
            push!(field_values, parse(type, parts[i]))
        else
            push!(field_values, parts[i])
        end
    end
    nt = NamedTuple{field_names}(field_values)
    return T(; nt...)
end

list(::Type{T}) where {T <: AbstractDataset} = read.(T, readdir(dir(T); join=true))

clear_cache!!() = (rm(DIR; force=true, recursive=true); mkpath(DIR))

Base.rm(dset::AbstractDataset) = isfile(local_path(dset)) && rm(local_path(dset))

#-----------------------------------------------------------------------------# RAPDataset
"""
    RAPDataset(; date, cycle, grid, product, forecast)

NOAA Rapid Refresh (RAP) dataset descriptor.

# Fields
- `date::Date`: Forecast initialization date (default: today)
- `cycle::String`: Model run time - "t00z", "t06z", "t12z", or "t18z" (default: "t00z")
- `grid::String`: Grid resolution - "awp130" (~13km) or "awp252" (~32km) (default: "awp130")
- `product::String`: Data type - "pgrb" (pressure), "sfcbf" (surface), or "isobf" (isentropic) (default: "pgrb")
- `forecast::String`: Forecast hour - "f00" to "f18" (default: "f00")
"""
@kwdef struct RAPDataset <: AbstractDataset
    date::Date = today()
    cycle::String = "t00z"
    grid::String = "awp130"
    product::String = "pgrb"
    forecast::String = "f00"  # "f00" to "f18"
end

"""
    url(dset::RAPDataset) -> String

Generate AWS S3 URL for the RAP dataset.
"""
function url(dset::RAPDataset)
    string("https://noaa-rap-pds.s3.amazonaws.com/rap.", Dates.format(dset.date, "yyyymmdd"),
    "/rap.", dset.cycle, ".", dset.grid, "pgrb", dset.forecast, ".grib2")
end

"""
    nextcycle(dset::RAPDataset) -> RAPDataset

Return a new RAPDataset with the cycle incremented to the next available cycle.
Cycles progress: t00z -> t06z -> t12z -> t18z -> t00z (next day).

# Example
```julia
dset = RAPDataset(date=Date(2024,1,15), cycle="t12z")
next = nextcycle(dset)  # Date(2024,1,15), cycle="t18z"

dset = RAPDataset(date=Date(2024,1,15), cycle="t18z")
next = nextcycle(dset)  # Date(2024,1,16), cycle="t00z"
```
"""
function nextcycle(dset::RAPDataset)
    cycle_map = Dict("t00z" => "t06z", "t06z" => "t12z", "t12z" => "t18z", "t18z" => "t00z")
    next_cycle = cycle_map[dset.cycle]
    next_date = next_cycle == "t00z" ? dset.date + Day(1) : dset.date
    return RAPDataset(
        date = next_date,
        cycle = next_cycle,
        grid = dset.grid,
        product = dset.product,
        forecast = dset.forecast
    )
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
@kwdef struct GFSDataset <: AbstractDataset
    date::Date = today()
    cycle::String = "00"  # "00", "06", "12", "18"
    resolution::String = "0p25"  # "0p25", "0p50", "1p00"
    product::String = "atmos"  # "atmos", "wave"
    forecast::String = "f000"  # "f000" to "f384"
end

"""
    url(dset::GFSDataset) -> String

Generate AWS S3 URL for the GFS dataset.
"""
function url(dset::GFSDataset)
    "https://noaa-gfs-bdp-pds.s3.amazonaws.com/gfs.$(Dates.format(dset.date, "yyyymmdd"))/" *
    "$(dset.cycle)/$(dset.product)/gfs.t$(dset.cycle)z.pgrb2.$(dset.resolution).$(dset.forecast)"
end

"""
    nextcycle(dset::GFSDataset) -> GFSDataset

Return a new GFSDataset with the cycle incremented to the next available cycle.
Cycles progress: 00 -> 06 -> 12 -> 18 -> 00 (next day).

# Example
```julia
dset = GFSDataset(date=Date(2024,1,15), cycle="12")
next = nextcycle(dset)  # Date(2024,1,15), cycle="18"

dset = GFSDataset(date=Date(2024,1,15), cycle="18")
next = nextcycle(dset)  # Date(2024,1,16), cycle="00"
```
"""
function nextcycle(dset::GFSDataset)
    cycle_map = Dict("00" => "06", "06" => "12", "12" => "18", "18" => "00")
    next_cycle = cycle_map[dset.cycle]
    next_date = next_cycle == "00" ? dset.date + Day(1) : dset.date
    return GFSDataset(
        date = next_date,
        cycle = next_cycle,
        resolution = dset.resolution,
        product = dset.product,
        forecast = dset.forecast
    )
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
@kwdef struct HRRRDataset <: AbstractDataset
    date::Date = today()
    cycle::String = "00"  # "00" to "23"
    region::String = "conus"  # "conus", "alaska"
    product::String = "wrfsfc"  # "wrfsfc", "wrfprs", "wrfnat", "wrfsub"
    forecast::String = "f00"  # "f00" to "f48"
end

"""
    url(dset::HRRRDataset) -> String

Generate AWS S3 URL for the HRRR dataset.
"""
function url(dset::HRRRDataset)
    "https://noaa-hrrr-bdp-pds.s3.amazonaws.com/hrrr.$(Dates.format(dset.date, "yyyymmdd"))/" *
    "$(dset.region)/hrrr.t$(dset.cycle)z.$(dset.product)$(dset.forecast).grib2"
end

"""
    nextcycle(dset::HRRRDataset) -> HRRRDataset

Return a new HRRRDataset with the cycle incremented to the next hour.
Cycles progress: 00 -> 01 -> 02 -> ... -> 23 -> 00 (next day).

# Example
```julia
dset = HRRRDataset(date=Date(2024,1,15), cycle="12")
next = nextcycle(dset)  # Date(2024,1,15), cycle="13"

dset = HRRRDataset(date=Date(2024,1,15), cycle="23")
next = nextcycle(dset)  # Date(2024,1,16), cycle="00"
```
"""
function nextcycle(dset::HRRRDataset)
    current_hour = parse(Int, dset.cycle)
    next_hour = (current_hour + 1) % 24
    next_cycle = lpad(next_hour, 2, '0')
    next_date = next_hour == 0 ? dset.date + Day(1) : dset.date
    return HRRRDataset(
        date = next_date,
        cycle = next_cycle,
        region = dset.region,
        product = dset.product,
        forecast = dset.forecast
    )
end

#-----------------------------------------------------------------------------# resolution_km
"""
    resolution_km(dset::AbstractDataset) -> Float64

Return the approximate grid resolution in kilometers for the dataset.

# Examples
```julia
resolution_km(RAPDataset(grid="awp130"))  # 13.0
resolution_km(RAPDataset(grid="awp252"))  # 32.0
resolution_km(GFSDataset(resolution="0p25"))  # 28.0
resolution_km(HRRRDataset())  # 3.0
```
"""
function resolution_km end

function resolution_km(dset::RAPDataset)
    dset.grid == "awp130" && return 13.0
    dset.grid == "awp252" && return 32.0
    error("Unknown RAP grid: $(dset.grid)")
end

function resolution_km(dset::GFSDataset)
    # GFS resolution is in degrees; 1° ≈ 111km at equator
    dset.resolution == "0p25" && return 28.0
    dset.resolution == "0p50" && return 56.0
    dset.resolution == "1p00" && return 111.0
    error("Unknown GFS resolution: $(dset.resolution)")
end

resolution_km(::HRRRDataset) = 3.0

#-----------------------------------------------------------------------------# metadata
"""
    metadata() -> NamedTuple

Return a table of dataset types with their field options and descriptions.

# Example
```julia
meta = metadata()
meta.RAPDataset  # Options for RAPDataset
```
"""
function metadata()
    (
        RAPDataset = (
            description = "Rapid Refresh - Continental US weather model",
            resolution_km = (awp130 = 13.0, awp252 = 32.0),
            fields = (
                date = "Forecast date (Date)",
                cycle = ["t00z", "t06z", "t12z", "t18z"],
                grid = ["awp130", "awp252"],
                product = ["pgrb", "sfcbf", "isobf"],
                forecast = "f00 to f18",
            ),
        ),
        GFSDataset = (
            description = "Global Forecast System - Global weather model",
            resolution_km = (var"0p25" = 28.0, var"0p50" = 56.0, var"1p00" = 111.0),
            fields = (
                date = "Forecast date (Date)",
                cycle = ["00", "06", "12", "18"],
                resolution = ["0p25", "0p50", "1p00"],
                product = ["atmos", "wave"],
                forecast = "f000 to f384",
            ),
        ),
        HRRRDataset = (
            description = "High-Resolution Rapid Refresh - 3km US weather model",
            resolution_km = 3.0,
            fields = (
                date = "Forecast date (Date)",
                cycle = "00 to 23",
                region = ["conus", "alaska"],
                product = ["wrfsfc", "wrfprs", "wrfnat", "wrfsub"],
                forecast = "f00 to f48",
            ),
        ),
    )
end

#-----------------------------------------------------------------------------# datasets
"""
    datasets(::Type{T}, start::DateTime, stop::DateTime) where {T <: AbstractDataset}

Return a Vector of all datasets of type `T` that cover the time period from `start` to `stop`.

Each dataset represents one model cycle (initialization time). The function returns all cycles
whose initialization time falls within the specified range.

# Examples
```julia
using Dates

# Get all HRRR datasets for a 6-hour window (hourly cycles)
datasets(HRRRDataset, DateTime(2024,1,15,0), DateTime(2024,1,15,6))

# Get all RAP datasets for a day (6-hourly cycles)
datasets(RAPDataset, DateTime(2024,1,15), DateTime(2024,1,16))

# Get all GFS datasets for a day (6-hourly cycles)
datasets(GFSDataset, DateTime(2024,1,15), DateTime(2024,1,16))
```
"""
function datasets end

function datasets(::Type{RAPDataset}, start::DateTime, stop::DateTime)
    result = RAPDataset[]
    cycles = ["t00z", "t06z", "t12z", "t18z"]
    cycle_hours = [0, 6, 12, 18]

    for date in Date(start):Day(1):Date(stop)
        for (cycle, hour) in zip(cycles, cycle_hours)
            dt = DateTime(date) + Hour(hour)
            if start <= dt <= stop
                push!(result, RAPDataset(date=date, cycle=cycle))
            end
        end
    end
    return result
end

function datasets(::Type{GFSDataset}, start::DateTime, stop::DateTime)
    result = GFSDataset[]
    cycles = ["00", "06", "12", "18"]
    cycle_hours = [0, 6, 12, 18]

    for date in Date(start):Day(1):Date(stop)
        for (cycle, hour) in zip(cycles, cycle_hours)
            dt = DateTime(date) + Hour(hour)
            if start <= dt <= stop
                push!(result, GFSDataset(date=date, cycle=cycle))
            end
        end
    end
    return result
end

function datasets(::Type{HRRRDataset}, start::DateTime, stop::DateTime)
    result = HRRRDataset[]

    for date in Date(start):Day(1):Date(stop)
        for hour in 0:23
            dt = DateTime(date) + Hour(hour)
            if start <= dt <= stop
                push!(result, HRRRDataset(date=date, cycle=lpad(hour, 2, '0')))
            end
        end
    end
    return result
end

#-----------------------------------------------------------------------------# Band/Variable Subsetting
"""
    Band

Information about a GRIB2 band/variable from an index file.

# Fields
- `line_number::Int`: Line number in GRIB2 file
- `byte_offset::Int`: Starting byte position
- `date::String`: Date string (format: d=YYYYMMDDHH)
- `variable::String`: Variable name (e.g., "TMP", "UGRD", "VGRD")
- `level::String`: Level description (e.g., "10 m above ground", "surface")
- `forecast_type::String`: Forecast type (e.g., "anl", "0-1 hour")
"""
struct Band
    line_number::Int
    byte_offset::Int
    date::String
    variable::String
    level::String
    forecast_type::String
end

function Base.show(io::IO, b::Band)
    print(io, "Band($(b.line_number): $(b.variable) at $(b.level))")
end

"""
    index_url(dset::AbstractDataset) -> String

Get the URL for the GRIB2 index file (.idx) corresponding to the dataset.
"""
index_url(dset::AbstractDataset) = url(dset) * ".idx"

"""
    bands(dset::AbstractDataset) -> Vector{Band}

Fetch and parse the index file to list all available bands/variables in the dataset.

# Example
```julia
dset = HRRRDataset(date=Date(2024,1,15), cycle="12")
bands_list = bands(dset)
# Find wind variables
wind_bands = filter(b -> contains(b.variable, "GRD") && contains(b.level, "10 m"), bands_list)
```
"""
function bands(dset::AbstractDataset)
    idx_url = index_url(dset)

    # Download index file to memory
    idx_content = Downloads.download(idx_url, IOBuffer()) |> take! |> String
    idx_lines = filter(!isempty, split(idx_content, '\n'))

    # Parse each line: line_num:byte_offset:date:variable:level:forecast_type
    result = Band[]
    for line in idx_lines
        parts = split(line, ':')
        if length(parts) >= 6
            push!(result, Band(
                parse(Int, parts[1]),
                parse(Int, parts[2]),
                parts[3:6]...,
            ))
        end
    end

    return result
end

"""
    get(dset::AbstractDataset, bands::Vector{Band}; output_path=nothing) -> String

Download only specific bands from the dataset using HTTP range requests.

Returns the path to the downloaded file containing only the requested bands.

# Arguments
- `dset`: Dataset descriptor
- `bands`: Vector of Band objects to download (from `bands(dset)`)
- `output_path`: Optional custom output path (default: adds "_subset" to filename)

# Example
```julia
dset = HRRRDataset(date=Date(2024,1,15), cycle="12")
all_bands = bands(dset)

# Select only wind components at 10m
wind_bands = filter(b ->
    (b.variable == "UGRD" || b.variable == "VGRD") &&
    contains(b.level, "10 m above ground"),
    all_bands
)

# Download just the wind data
wind_file = get(dset, wind_bands)
```
"""
function Base.get(dset::AbstractDataset, bands_to_get::Vector{Band}; output_path=nothing)
    isempty(bands_to_get) && error("No bands specified")

    # Determine output path
    if isnothing(output_path)
        base_path = local_path(dset)
        name, ext = splitext(base_path)
        output_path = name * "_subset" * ext
    end

    # Return cached file if it exists
    if isfile(output_path)
        return output_path
    end

    # Get all bands to determine byte ranges
    all_bands = bands(dset)

    # Create a mapping of byte offsets
    byte_ranges = Tuple{Int,Int}[]
    for band in bands_to_get
        idx = findfirst(b -> b.line_number == band.line_number, all_bands)
        if isnothing(idx)
            error("Band $(band.line_number) not found in dataset")
        end

        start_byte = all_bands[idx].byte_offset

        # End byte is the start of the next band (or end of file)
        if idx < length(all_bands)
            end_byte = all_bands[idx + 1].byte_offset - 1
        else
            # For the last band, we need to download to the end
            # We'll use a large number or omit the end byte
            end_byte = -1  # Signal to download to end
        end

        push!(byte_ranges, (start_byte, end_byte))
    end

    # Download each band's byte range
    data_url = url(dset)

    open(output_path, "w") do io
        for (start_byte, end_byte) in byte_ranges
            # Construct range header
            range_str = if end_byte == -1
                "bytes=$(start_byte)-"
            else
                "bytes=$(start_byte)-$(end_byte)"
            end

            # Download this range
            temp_io = IOBuffer()
            Downloads.download(data_url, temp_io; headers=["Range" => range_str])
            seekstart(temp_io)
            write(io, read(temp_io))
        end
    end

    return output_path
end


end
