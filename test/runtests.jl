using RapidRefreshData
using Test
using Dates

@testset "RapidRefreshData.jl" begin
    @testset "RAPDataset construction" begin
        # Test default construction
        dset_default = RapidRefreshData.RAPDataset()
        @test dset_default.date == today()
        @test dset_default.cycle == "t00z"
        @test dset_default.grid == "awp130"
        @test dset_default.product == "pgrb"
        @test dset_default.forecast == "f00"

        # Test custom construction with keyword arguments
        test_date = Date(2024, 1, 15)
        dset_custom = RapidRefreshData.RAPDataset(
            date = test_date,
            cycle = "t12z",
            grid = "awp252",
            product = "pgrb",
            forecast = "f06"
        )
        @test dset_custom.date == test_date
        @test dset_custom.cycle == "t12z"
        @test dset_custom.grid == "awp252"
        @test dset_custom.product == "pgrb"
        @test dset_custom.forecast == "f06"

        # Test partial custom construction (some defaults, some custom)
        dset_partial = RapidRefreshData.RAPDataset(cycle = "t18z", forecast = "f03")
        @test dset_partial.date == today()
        @test dset_partial.cycle == "t18z"
        @test dset_partial.grid == "awp130"
        @test dset_partial.forecast == "f03"
    end

    @testset "Base.read(::Type{RAPDataset}, path)" begin
        # Test parsing a standard RAP filename (new format includes all fields)
        path1 = "data_20240115_t00z_awp130_pgrb_f00.grib2"
        dset1 = read(RapidRefreshData.RAPDataset, path1)
        @test dset1.date == Date(2024, 1, 15)
        @test dset1.cycle == "t00z"
        @test dset1.grid == "awp130"
        @test dset1.product == "pgrb"
        @test dset1.forecast == "f00"

        # Test parsing with different parameters
        path2 = "data_20241225_t12z_awp252_pgrb_f06.grib2"
        dset2 = read(RapidRefreshData.RAPDataset, path2)
        @test dset2.date == Date(2024, 12, 25)
        @test dset2.cycle == "t12z"
        @test dset2.grid == "awp252"
        @test dset2.product == "pgrb"
        @test dset2.forecast == "f06"

        # Test parsing with full path
        full_path = "/some/directory/data_20240305_t18z_awp130_pgrb_f03.grib2"
        dset3 = read(RapidRefreshData.RAPDataset, full_path)
        @test dset3.date == Date(2024, 3, 5)
        @test dset3.cycle == "t18z"
        @test dset3.grid == "awp130"
        @test dset3.product == "pgrb"
        @test dset3.forecast == "f03"

        # Test that read works with broadcast
        paths = ["data_20240101_t00z_awp130_pgrb_f00.grib2", "data_20240102_t06z_awp252_pgrb_f12.grib2"]
        dsets = read.(RapidRefreshData.RAPDataset, paths)
        @test length(dsets) == 2
        @test dsets[1].date == Date(2024, 1, 1)
        @test dsets[2].date == Date(2024, 1, 2)
        @test dsets[1].cycle == "t00z"
        @test dsets[2].cycle == "t06z"
    end

    @testset "url() function" begin
        # Test URL generation with default dataset
        test_date = Date(2024, 1, 15)
        dset = RapidRefreshData.RAPDataset(date = test_date)
        expected_url = "https://noaa-rap-pds.s3.amazonaws.com/rap.20240115/rap.t00z.awp130pgrbf00.grib2"
        @test RapidRefreshData.url(dset) == expected_url

        # Test URL generation with custom parameters
        dset2 = RapidRefreshData.RAPDataset(
            date = Date(2024, 12, 25),
            cycle = "t12z",
            grid = "awp252",
            forecast = "f06"
        )
        expected_url2 = "https://noaa-rap-pds.s3.amazonaws.com/rap.20241225/rap.t12z.awp252pgrbf06.grib2"
        @test RapidRefreshData.url(dset2) == expected_url2

        # Test with different date formats
        dset3 = RapidRefreshData.RAPDataset(date = Date(2024, 3, 5))
        expected_url3 = "https://noaa-rap-pds.s3.amazonaws.com/rap.20240305/rap.t00z.awp130pgrbf00.grib2"
        @test RapidRefreshData.url(dset3) == expected_url3
    end

    @testset "local_path() function" begin
        # Test local path generation
        test_date = Date(2024, 1, 15)
        dset = RapidRefreshData.RAPDataset(date = test_date)
        local_path_result = RapidRefreshData.local_path(dset)

        # Check that path includes the type-specific directory
        @test occursin("RAPDataset", local_path_result)

        # Check that filename has correct format (includes all fields now)
        @test occursin("data_20240115_t00z_awp130_pgrb_f00.grib2", local_path_result)

        # Test with custom parameters
        dset2 = RapidRefreshData.RAPDataset(
            date = Date(2024, 12, 25),
            cycle = "t12z",
            grid = "awp252",
            forecast = "f06"
        )
        local_path_result2 = RapidRefreshData.local_path(dset2)
        @test occursin("data_20241225_t12z_awp252_pgrb_f06.grib2", local_path_result2)

        # Verify path ends with .grib2
        @test endswith(local_path_result, ".grib2")
        @test endswith(local_path_result2, ".grib2")
    end

    @testset "Scratch directory initialization" begin
        # Test that scratch directory is initialized
        @test RapidRefreshData.DIR != ""
        @test isdir(RapidRefreshData.DIR)

        # Test type-specific directories
        @test isdir(RapidRefreshData.dir(RapidRefreshData.RAPDataset))
        @test isdir(RapidRefreshData.dir(RapidRefreshData.GFSDataset))
        @test isdir(RapidRefreshData.dir(RapidRefreshData.HRRRDataset))
    end

    @testset "get() function" begin
        # Note: We don't test actual downloads here to avoid network dependencies
        # and large file downloads in CI. Instead we test the logic.

        test_date = Date(2024, 1, 15)
        dset = RapidRefreshData.RAPDataset(date = test_date)

        # Test that get returns a path (string)
        @test hasmethod(get, (RapidRefreshData.RAPDataset,))

        # Verify that local_path returns the expected path format
        path = RapidRefreshData.local_path(dset)
        @test isa(path, String)
        @test endswith(path, ".grib2")
    end

    @testset "list() function" begin
        # Create some test dataset files
        test_dset1 = RapidRefreshData.RAPDataset(
            date = Date(2024, 1, 15),
            cycle = "t00z",
            grid = "awp130",
            forecast = "f00"
        )
        test_dset2 = RapidRefreshData.RAPDataset(
            date = Date(2024, 1, 16),
            cycle = "t12z",
            grid = "awp252",
            forecast = "f06"
        )

        # Create temporary files to test with
        path1 = RapidRefreshData.local_path(test_dset1)
        path2 = RapidRefreshData.local_path(test_dset2)

        # Write dummy content to the files
        write(path1, "test data 1")
        write(path2, "test data 2")

        try
            # Get all local datasets
            datasets = RapidRefreshData.list(RapidRefreshData.RAPDataset)

            # Should return an array of RAPDatasets
            @test isa(datasets, Vector{RapidRefreshData.RAPDataset})

            # Should contain at least our test datasets
            @test length(datasets) >= 2

            # Check that our test datasets are in the list
            dates = [d.date for d in datasets]
            cycles = [d.cycle for d in datasets]
            grids = [d.grid for d in datasets]
            forecasts = [d.forecast for d in datasets]

            @test Date(2024, 1, 15) in dates
            @test Date(2024, 1, 16) in dates
            @test "t00z" in cycles
            @test "t12z" in cycles
            @test "awp130" in grids
            @test "awp252" in grids
            @test "f00" in forecasts
            @test "f06" in forecasts
        finally
            # Clean up test files
            rm(path1, force=true)
            rm(path2, force=true)
        end
    end

    @testset "rm() function" begin
        # Create a test dataset file
        test_dset = RapidRefreshData.RAPDataset(
            date = Date(2024, 2, 20),
            cycle = "t06z",
            grid = "awp130",
            forecast = "f03"
        )

        path = RapidRefreshData.local_path(test_dset)

        # Write dummy content to create the file
        write(path, "test data for deletion")

        # Verify file exists
        @test isfile(path)

        # Clear the dataset
        RapidRefreshData.rm(test_dset)

        # Verify file was removed
        @test !isfile(path)

        # Test clearing a dataset that doesn't exist (should not error)
        test_dset_nonexistent = RapidRefreshData.RAPDataset(
            date = Date(2024, 12, 31),
            cycle = "t18z",
            grid = "awp252",
            forecast = "f12"
        )

        # This should not throw an error
        @test_nowarn RapidRefreshData.rm(test_dset_nonexistent)

        # Verify the non-existent file still doesn't exist
        @test !isfile(RapidRefreshData.local_path(test_dset_nonexistent))
    end

    @testset "GFSDataset construction" begin
        # Test default construction
        dset_default = RapidRefreshData.GFSDataset()
        @test dset_default.date == today()
        @test dset_default.cycle == "00"
        @test dset_default.resolution == "0p25"
        @test dset_default.product == "atmos"
        @test dset_default.forecast == "f000"

        # Test custom construction with keyword arguments
        test_date = Date(2024, 1, 15)
        dset_custom = RapidRefreshData.GFSDataset(
            date = test_date,
            cycle = "12",
            resolution = "0p50",
            product = "wave",
            forecast = "f006"
        )
        @test dset_custom.date == test_date
        @test dset_custom.cycle == "12"
        @test dset_custom.resolution == "0p50"
        @test dset_custom.product == "wave"
        @test dset_custom.forecast == "f006"

        # Test partial custom construction
        dset_partial = RapidRefreshData.GFSDataset(cycle = "18", forecast = "f012")
        @test dset_partial.date == today()
        @test dset_partial.cycle == "18"
        @test dset_partial.resolution == "0p25"
        @test dset_partial.forecast == "f012"
    end

    @testset "Base.read(::Type{GFSDataset}, path)" begin
        # Test parsing a standard GFS filename
        path1 = "data_20240115_00_0p25_atmos_f000.grib2"
        dset1 = read(RapidRefreshData.GFSDataset, path1)
        @test dset1.date == Date(2024, 1, 15)
        @test dset1.cycle == "00"
        @test dset1.resolution == "0p25"
        @test dset1.product == "atmos"
        @test dset1.forecast == "f000"

        # Test parsing with different parameters
        path2 = "data_20241225_12_0p50_wave_f024.grib2"
        dset2 = read(RapidRefreshData.GFSDataset, path2)
        @test dset2.date == Date(2024, 12, 25)
        @test dset2.cycle == "12"
        @test dset2.resolution == "0p50"
        @test dset2.product == "wave"
        @test dset2.forecast == "f024"

        # Test parsing with full path
        full_path = "/some/directory/data_20240305_06_1p00_atmos_f012.grib2"
        dset3 = read(RapidRefreshData.GFSDataset, full_path)
        @test dset3.date == Date(2024, 3, 5)
        @test dset3.cycle == "06"
        @test dset3.resolution == "1p00"
        @test dset3.product == "atmos"
        @test dset3.forecast == "f012"

        # Test that read works with broadcast
        paths = ["data_20240101_00_0p25_atmos_f000.grib2", "data_20240102_18_0p50_wave_f384.grib2"]
        dsets = read.(RapidRefreshData.GFSDataset, paths)
        @test length(dsets) == 2
        @test dsets[1].date == Date(2024, 1, 1)
        @test dsets[2].date == Date(2024, 1, 2)
        @test dsets[1].cycle == "00"
        @test dsets[2].cycle == "18"
        @test dsets[1].product == "atmos"
        @test dsets[2].product == "wave"
    end

    @testset "GFSDataset url() function" begin
        # Test URL generation with default dataset
        test_date = Date(2024, 1, 15)
        dset = RapidRefreshData.GFSDataset(date = test_date)
        expected_url = "https://noaa-gfs-bdp-pds.s3.amazonaws.com/gfs.20240115/00/atmos/gfs.t00z.pgrb2.0p25.f000"
        @test RapidRefreshData.url(dset) == expected_url

        # Test URL generation with custom parameters
        dset2 = RapidRefreshData.GFSDataset(
            date = Date(2024, 12, 25),
            cycle = "12",
            resolution = "0p50",
            product = "wave",
            forecast = "f024"
        )
        expected_url2 = "https://noaa-gfs-bdp-pds.s3.amazonaws.com/gfs.20241225/12/wave/gfs.t12z.pgrb2.0p50.f024"
        @test RapidRefreshData.url(dset2) == expected_url2

        # Test with different date formats
        dset3 = RapidRefreshData.GFSDataset(date = Date(2024, 3, 5))
        expected_url3 = "https://noaa-gfs-bdp-pds.s3.amazonaws.com/gfs.20240305/00/atmos/gfs.t00z.pgrb2.0p25.f000"
        @test RapidRefreshData.url(dset3) == expected_url3
    end

    @testset "GFSDataset local_path() function" begin
        # Test local path generation
        test_date = Date(2024, 1, 15)
        dset = RapidRefreshData.GFSDataset(date = test_date)
        local_path_result = RapidRefreshData.local_path(dset)

        # Check that path includes the type-specific directory
        @test occursin("GFSDataset", local_path_result)

        # Check that filename has correct format
        @test occursin("data_20240115_00_0p25_atmos_f000.grib2", local_path_result)

        # Test with custom parameters
        dset2 = RapidRefreshData.GFSDataset(
            date = Date(2024, 12, 25),
            cycle = "12",
            resolution = "0p50",
            product = "wave",
            forecast = "f024"
        )
        local_path_result2 = RapidRefreshData.local_path(dset2)
        @test occursin("data_20241225_12_0p50_wave_f024.grib2", local_path_result2)

        # Verify path ends with .grib2
        @test endswith(local_path_result, ".grib2")
        @test endswith(local_path_result2, ".grib2")
    end

    @testset "HRRRDataset construction" begin
        # Test default construction
        dset_default = RapidRefreshData.HRRRDataset()
        @test dset_default.date == today()
        @test dset_default.cycle == "00"
        @test dset_default.region == "conus"
        @test dset_default.product == "wrfsfc"
        @test dset_default.forecast == "f00"

        # Test custom construction with keyword arguments
        test_date = Date(2024, 1, 15)
        dset_custom = RapidRefreshData.HRRRDataset(
            date = test_date,
            cycle = "12",
            region = "alaska",
            product = "wrfprs",
            forecast = "f06"
        )
        @test dset_custom.date == test_date
        @test dset_custom.cycle == "12"
        @test dset_custom.region == "alaska"
        @test dset_custom.product == "wrfprs"
        @test dset_custom.forecast == "f06"

        # Test partial custom construction
        dset_partial = RapidRefreshData.HRRRDataset(cycle = "18", forecast = "f12")
        @test dset_partial.date == today()
        @test dset_partial.cycle == "18"
        @test dset_partial.region == "conus"
        @test dset_partial.forecast == "f12"
    end

    @testset "Base.read(::Type{HRRRDataset}, path)" begin
        # Test parsing a standard HRRR filename
        path1 = "data_20240115_00_conus_wrfsfc_f00.grib2"
        dset1 = read(RapidRefreshData.HRRRDataset, path1)
        @test dset1.date == Date(2024, 1, 15)
        @test dset1.cycle == "00"
        @test dset1.region == "conus"
        @test dset1.product == "wrfsfc"
        @test dset1.forecast == "f00"

        # Test parsing with different parameters
        path2 = "data_20241225_12_alaska_wrfprs_f24.grib2"
        dset2 = read(RapidRefreshData.HRRRDataset, path2)
        @test dset2.date == Date(2024, 12, 25)
        @test dset2.cycle == "12"
        @test dset2.region == "alaska"
        @test dset2.product == "wrfprs"
        @test dset2.forecast == "f24"

        # Test parsing with full path
        full_path = "/some/directory/data_20240305_18_conus_wrfnat_f03.grib2"
        dset3 = read(RapidRefreshData.HRRRDataset, full_path)
        @test dset3.date == Date(2024, 3, 5)
        @test dset3.cycle == "18"
        @test dset3.region == "conus"
        @test dset3.product == "wrfnat"
        @test dset3.forecast == "f03"

        # Test that read works with broadcast
        paths = ["data_20240101_00_conus_wrfsfc_f00.grib2", "data_20240102_06_alaska_wrfprs_f12.grib2"]
        dsets = read.(RapidRefreshData.HRRRDataset, paths)
        @test length(dsets) == 2
        @test dsets[1].date == Date(2024, 1, 1)
        @test dsets[2].date == Date(2024, 1, 2)
        @test dsets[1].cycle == "00"
        @test dsets[2].cycle == "06"
        @test dsets[1].region == "conus"
        @test dsets[2].region == "alaska"
    end

    @testset "HRRRDataset url() function" begin
        # Test URL generation with default dataset
        test_date = Date(2024, 1, 15)
        dset = RapidRefreshData.HRRRDataset(date = test_date)
        expected_url = "https://noaa-hrrr-bdp-pds.s3.amazonaws.com/hrrr.20240115/conus/hrrr.t00z.wrfsfcf00.grib2"
        @test RapidRefreshData.url(dset) == expected_url

        # Test URL generation with custom parameters
        dset2 = RapidRefreshData.HRRRDataset(
            date = Date(2024, 12, 25),
            cycle = "12",
            region = "alaska",
            product = "wrfprs",
            forecast = "f06"
        )
        expected_url2 = "https://noaa-hrrr-bdp-pds.s3.amazonaws.com/hrrr.20241225/alaska/hrrr.t12z.wrfprsf06.grib2"
        @test RapidRefreshData.url(dset2) == expected_url2

        # Test with different date formats
        dset3 = RapidRefreshData.HRRRDataset(date = Date(2024, 3, 5), product = "wrfnat", forecast = "f18")
        expected_url3 = "https://noaa-hrrr-bdp-pds.s3.amazonaws.com/hrrr.20240305/conus/hrrr.t00z.wrfnatf18.grib2"
        @test RapidRefreshData.url(dset3) == expected_url3
    end

    @testset "HRRRDataset local_path() function" begin
        # Test local path generation
        test_date = Date(2024, 1, 15)
        dset = RapidRefreshData.HRRRDataset(date = test_date)
        local_path_result = RapidRefreshData.local_path(dset)

        # Check that path includes the type-specific directory
        @test occursin("HRRRDataset", local_path_result)

        # Check that filename has correct format
        @test occursin("data_20240115_00_conus_wrfsfc_f00.grib2", local_path_result)

        # Test with custom parameters
        dset2 = RapidRefreshData.HRRRDataset(
            date = Date(2024, 12, 25),
            cycle = "12",
            region = "alaska",
            product = "wrfprs",
            forecast = "f24"
        )
        local_path_result2 = RapidRefreshData.local_path(dset2)
        @test occursin("data_20241225_12_alaska_wrfprs_f24.grib2", local_path_result2)

        # Verify path ends with .grib2
        @test endswith(local_path_result, ".grib2")
        @test endswith(local_path_result2, ".grib2")
    end

    @testset "nextcycle() - RAPDataset" begin
        # Test cycling within same day
        dset1 = RapidRefreshData.RAPDataset(date=Date(2024,1,15), cycle="t00z")
        next1 = RapidRefreshData.nextcycle(dset1)
        @test next1.date == Date(2024,1,15)
        @test next1.cycle == "t06z"
        @test next1.grid == dset1.grid
        @test next1.product == dset1.product
        @test next1.forecast == dset1.forecast

        dset2 = RapidRefreshData.RAPDataset(date=Date(2024,1,15), cycle="t06z")
        next2 = RapidRefreshData.nextcycle(dset2)
        @test next2.date == Date(2024,1,15)
        @test next2.cycle == "t12z"

        dset3 = RapidRefreshData.RAPDataset(date=Date(2024,1,15), cycle="t12z")
        next3 = RapidRefreshData.nextcycle(dset3)
        @test next3.date == Date(2024,1,15)
        @test next3.cycle == "t18z"

        # Test day rollover
        dset4 = RapidRefreshData.RAPDataset(date=Date(2024,1,15), cycle="t18z")
        next4 = RapidRefreshData.nextcycle(dset4)
        @test next4.date == Date(2024,1,16)
        @test next4.cycle == "t00z"

        # Test chaining (t12z -> t18z -> t00z next day)
        dset5 = RapidRefreshData.RAPDataset(date=Date(2024,1,15), cycle="t12z", grid="awp252")
        next5 = RapidRefreshData.nextcycle(RapidRefreshData.nextcycle(dset5))
        @test next5.date == Date(2024,1,16)
        @test next5.cycle == "t00z"
        @test next5.grid == "awp252"  # Preserve other fields
    end

    @testset "nextcycle() - GFSDataset" begin
        # Test cycling within same day
        dset1 = RapidRefreshData.GFSDataset(date=Date(2024,1,15), cycle="00")
        next1 = RapidRefreshData.nextcycle(dset1)
        @test next1.date == Date(2024,1,15)
        @test next1.cycle == "06"
        @test next1.resolution == dset1.resolution
        @test next1.product == dset1.product
        @test next1.forecast == dset1.forecast

        dset2 = RapidRefreshData.GFSDataset(date=Date(2024,1,15), cycle="06")
        next2 = RapidRefreshData.nextcycle(dset2)
        @test next2.date == Date(2024,1,15)
        @test next2.cycle == "12"

        dset3 = RapidRefreshData.GFSDataset(date=Date(2024,1,15), cycle="12")
        next3 = RapidRefreshData.nextcycle(dset3)
        @test next3.date == Date(2024,1,15)
        @test next3.cycle == "18"

        # Test day rollover
        dset4 = RapidRefreshData.GFSDataset(date=Date(2024,1,15), cycle="18")
        next4 = RapidRefreshData.nextcycle(dset4)
        @test next4.date == Date(2024,1,16)
        @test next4.cycle == "00"

        # Test chaining (12 -> 18 -> 00 next day)
        dset5 = RapidRefreshData.GFSDataset(date=Date(2024,1,15), cycle="12", resolution="0p50")
        next5 = RapidRefreshData.nextcycle(RapidRefreshData.nextcycle(dset5))
        @test next5.date == Date(2024,1,16)
        @test next5.cycle == "00"
        @test next5.resolution == "0p50"  # Preserve other fields
    end

    @testset "nextcycle() - HRRRDataset" begin
        # Test cycling within same day
        dset1 = RapidRefreshData.HRRRDataset(date=Date(2024,1,15), cycle="00")
        next1 = RapidRefreshData.nextcycle(dset1)
        @test next1.date == Date(2024,1,15)
        @test next1.cycle == "01"
        @test next1.region == dset1.region
        @test next1.product == dset1.product
        @test next1.forecast == dset1.forecast

        dset2 = RapidRefreshData.HRRRDataset(date=Date(2024,1,15), cycle="12")
        next2 = RapidRefreshData.nextcycle(dset2)
        @test next2.date == Date(2024,1,15)
        @test next2.cycle == "13"

        dset3 = RapidRefreshData.HRRRDataset(date=Date(2024,1,15), cycle="22")
        next3 = RapidRefreshData.nextcycle(dset3)
        @test next3.date == Date(2024,1,15)
        @test next3.cycle == "23"

        # Test day rollover
        dset4 = RapidRefreshData.HRRRDataset(date=Date(2024,1,15), cycle="23")
        next4 = RapidRefreshData.nextcycle(dset4)
        @test next4.date == Date(2024,1,16)
        @test next4.cycle == "00"

        # Test chaining - go through multiple hours
        dset5 = RapidRefreshData.HRRRDataset(date=Date(2024,1,15), cycle="22", region="alaska")
        next5 = dset5
        for _ in 1:5
            next5 = RapidRefreshData.nextcycle(next5)
        end
        @test next5.date == Date(2024,1,16)
        @test next5.cycle == "03"
        @test next5.region == "alaska"  # Preserve other fields

        # Test single-digit cycles
        dset6 = RapidRefreshData.HRRRDataset(date=Date(2024,1,15), cycle="08")
        next6 = RapidRefreshData.nextcycle(dset6)
        @test next6.cycle == "09"

        dset7 = RapidRefreshData.HRRRDataset(date=Date(2024,1,15), cycle="09")
        next7 = RapidRefreshData.nextcycle(dset7)
        @test next7.cycle == "10"
    end

    @testset "Band subsetting" begin
        # Test with HRRR dataset
        test_date = Date(2024, 1, 15)
        dset = RapidRefreshData.HRRRDataset(
            date = test_date,
            cycle = "12",
            forecast = "f00"
        )

        # Test index_url
        idx_url = RapidRefreshData.index_url(dset)
        @test occursin(".idx", idx_url)
        @test occursin("hrrr.t12z.wrfsfcf00.grib2.idx", idx_url)

        # Test bands() function
        # Note: This requires network access, so we'll test the structure
        @test hasmethod(RapidRefreshData.bands, (RapidRefreshData.HRRRDataset,))

        # Test Band struct
        band = RapidRefreshData.Band(1, 0, "d=2024011512", "TMP", "2 m above ground", "anl")
        @test band.line_number == 1
        @test band.byte_offset == 0
        @test band.variable == "TMP"
        @test band.level == "2 m above ground"
        @test band.forecast_type == "anl"

        # Test show method
        io = IOBuffer()
        show(io, band)
        output = String(take!(io))
        @test occursin("Band(1: TMP at 2 m above ground)", output)

        # Test get with bands (method exists)
        @test hasmethod(get, (RapidRefreshData.HRRRDataset, Vector{RapidRefreshData.Band}))

        # Test that get with bands works for all dataset types
        @test hasmethod(get, (RapidRefreshData.RAPDataset, Vector{RapidRefreshData.Band}))
        @test hasmethod(get, (RapidRefreshData.GFSDataset, Vector{RapidRefreshData.Band}))
    end
end
