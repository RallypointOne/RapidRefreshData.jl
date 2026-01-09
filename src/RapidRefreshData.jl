module RapidRefreshData

using Dates, Scratch

const base_url = "https://noaa-rap-pds.s3.amazonaws.com/rap."


#-----------------------------------------------------------------------------# __init__
dir::String = ""

function __init__()
    global dir = Scratch.@get_scratch!("datasets")
end

#-----------------------------------------------------------------------------# Dataset
# Products:
# pgrb: Pressure Levels
# sfcbf: Surface Fields
# isobf: Isentropic f00

@kwdef struct Dataset
    date::Date = today()
    cycle_time::String = "t00z"
    grid::String = "awp130"
    product::String = "pgrb"
    forecast::String = "f00"  # "f00" to "f18"
end

function Base.show(io::IO, dset::Dataset)
    (;date, cycle_time, grid, product, forecast) = dset
    print(io, "Dataset", (; date=string(date), cycle_time, grid, product, forecast))
end

function Base.parse(::Type{Dataset}, local_path::String)
    filename = split(basename(local_path), ".")[1]
    parts = split(filename, "_")
    date = Date(parts[1], "yyyymmdd")
    cycle_time = parts[2]
    grid = parts[3]
    forecast = replace(parts[4], ".grib2" => "")
    return Dataset(; date, cycle_time, grid, forecast)
end

function url(dset::Dataset)
    "$base_url$(Dates.format(dset.date, "yyyymmdd"))/rap.$(dset.cycle_time).$(dset.grid)pgrb$(dset.forecast).grib2"
end

function local_path(dset::Dataset)
    joinpath(dir, "$(Dates.format(dset.date, "yyyymmdd"))_$(dset.cycle_time)_$(dset.grid)_$(dset.forecast).grib2")
end

function Base.download(dset::Dataset)
    isfile(local_path(dset)) ? local_path(dset) : Base.download(url(dset), local_path(dset))
end

function local_datasets()
    files = readdir(dir)
    parse.(Dataset, files)
end

function clear_local_dataset!(dset::Dataset)
    isfile(local_path(dset)) && rm(local_path(dset))
end


end
