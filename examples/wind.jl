import RapidRefreshData as RRD

using Rasters, ArchGDAL, Dates, GRIBDatasets

#-----------------------------------------------------------------------------# get HRRR Dataset
dset = RRD.HRRRDataset(
    date = Date(2024, 1, 15),
    cycle = "12",
    region = "conus",
    product = "wrfsfc",
    forecast = "f06"
)

bands = RRD.bands(dset)

wind_bands = filter(bands) do b
    b.variable in ["UGRD", "VGRD"] && b.level == "10 m above ground"
end

path = get(dset, wind_bands)

r = Raster(path, checkmem=false)

u = r[:, :, 1]
v = r[:, :, 2]
