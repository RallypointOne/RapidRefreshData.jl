# RapidRefreshData

[![Build Status](https://github.com/joshday/RapidRefreshData.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/joshday/RapidRefreshData.jl/actions/workflows/CI.yml?query=branch%3Amain)


# Usage

```julia
using RapidRefreshData: Dataset
using Rasters, ArchGDAL

data = Dataset()

filepath = download(data)

r = Raster(filepath; checkmem=false)
```
