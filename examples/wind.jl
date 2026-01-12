import RapidRefreshData as RRD

using Rasters, ArchGDAL, Dates

datasets = [RRD.RAPDataset(date = Date(2024, 6, 15), cycle_time = "t0$(i)z") for i in 0:5]
