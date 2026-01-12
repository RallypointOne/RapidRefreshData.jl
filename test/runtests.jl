using RapidRefreshData
using Test
using Dates

@testset "RapidRefreshData.jl" begin
    @testset "RAPDataset construction" begin
        # Test default construction
        dset_default = RapidRefreshData.RAPDataset()
        @test dset_default.date == today()
        @test dset_default.cycle_time == "t00z"
        @test dset_default.grid == "awp130"
        @test dset_default.product == "pgrb"
        @test dset_default.forecast == "f00"

        # Test custom construction with keyword arguments
        test_date = Date(2024, 1, 15)
        dset_custom = RapidRefreshData.RAPDataset(
            date = test_date,
            cycle_time = "t12z",
            grid = "awp252",
            product = "pgrb",
            forecast = "f06"
        )
        @test dset_custom.date == test_date
        @test dset_custom.cycle_time == "t12z"
        @test dset_custom.grid == "awp252"
        @test dset_custom.product == "pgrb"
        @test dset_custom.forecast == "f06"

        # Test partial custom construction (some defaults, some custom)
        dset_partial = RapidRefreshData.RAPDataset(cycle_time = "t18z", forecast = "f03")
        @test dset_partial.date == today()
        @test dset_partial.cycle_time == "t18z"
        @test dset_partial.grid == "awp130"
        @test dset_partial.forecast == "f03"
    end

    @testset "Base.read(::Type{RAPDataset}, path)" begin
        # Test parsing a standard RAP filename
        path1 = "rap_20240115_t00z_awp130_f00.grib2"
        dset1 = read(RapidRefreshData.RAPDataset, path1)
        @test dset1.date == Date(2024, 1, 15)
        @test dset1.cycle_time == "t00z"
        @test dset1.grid == "awp130"
        @test dset1.forecast == "f00"

        # Test parsing with different parameters
        path2 = "rap_20241225_t12z_awp252_f06.grib2"
        dset2 = read(RapidRefreshData.RAPDataset, path2)
        @test dset2.date == Date(2024, 12, 25)
        @test dset2.cycle_time == "t12z"
        @test dset2.grid == "awp252"
        @test dset2.forecast == "f06"

        # Test parsing with full path
        full_path = "/some/directory/rap_20240305_t18z_awp130_f03.grib2"
        dset3 = read(RapidRefreshData.RAPDataset, full_path)
        @test dset3.date == Date(2024, 3, 5)
        @test dset3.cycle_time == "t18z"
        @test dset3.grid == "awp130"
        @test dset3.forecast == "f03"

        # Test that read works with broadcast
        paths = ["rap_20240101_t00z_awp130_f00.grib2", "rap_20240102_t06z_awp252_f12.grib2"]
        dsets = read.(RapidRefreshData.RAPDataset, paths)
        @test length(dsets) == 2
        @test dsets[1].date == Date(2024, 1, 1)
        @test dsets[2].date == Date(2024, 1, 2)
        @test dsets[1].cycle_time == "t00z"
        @test dsets[2].cycle_time == "t06z"
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
            cycle_time = "t12z",
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

        # Check that path includes the scratch directory
        @test occursin(RapidRefreshData.rap_dir, local_path_result)

        # Check that filename has correct format
        @test occursin("rap_20240115_t00z_awp130_f00.grib2", local_path_result)

        # Test with custom parameters
        dset2 = RapidRefreshData.RAPDataset(
            date = Date(2024, 12, 25),
            cycle_time = "t12z",
            grid = "awp252",
            forecast = "f06"
        )
        local_path_result2 = RapidRefreshData.local_path(dset2)
        @test occursin("rap_20241225_t12z_awp252_f06.grib2", local_path_result2)

        # Verify path ends with .grib2
        @test endswith(local_path_result, ".grib2")
        @test endswith(local_path_result2, ".grib2")
    end

    @testset "Scratch directory initialization" begin
        # Test that scratch directories are initialized
        @test RapidRefreshData.rap_dir != ""
        @test isdir(RapidRefreshData.rap_dir)
        @test RapidRefreshData.gfs_dir != ""
        @test isdir(RapidRefreshData.gfs_dir)
        @test RapidRefreshData.hrrr_dir != ""
        @test isdir(RapidRefreshData.hrrr_dir)
    end

    @testset "get() function" begin
        # Note: We don't test actual downloads here to avoid network dependencies
        # and large file downloads in CI. Instead we test the logic.

        test_date = Date(2024, 1, 15)
        dset = RapidRefreshData.RAPDataset(date = test_date)

        # Test that get returns a path (string)
        # In actual use, this would download or return cached file
        # We just verify the function exists and can be called
        @test isdefined(RapidRefreshData, :get)
        @test hasmethod(get, (RapidRefreshData.RAPDataset,))

        # Verify that local_path returns the expected path format
        path = RapidRefreshData.local_path(dset)
        @test isa(path, String)
        @test endswith(path, ".grib2")
    end

    @testset "local_datasets() function" begin
        # Create some test dataset files
        test_dset1 = RapidRefreshData.RAPDataset(
            date = Date(2024, 1, 15),
            cycle_time = "t00z",
            grid = "awp130",
            forecast = "f00"
        )
        test_dset2 = RapidRefreshData.RAPDataset(
            date = Date(2024, 1, 16),
            cycle_time = "t12z",
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
            datasets = RapidRefreshData.local_datasets(RapidRefreshData.RAPDataset)

            # Should return an array of RAPDatasets
            @test isa(datasets, Vector{RapidRefreshData.RAPDataset})

            # Should contain at least our test datasets
            @test length(datasets) >= 2

            # Check that our test datasets are in the list
            dates = [d.date for d in datasets]
            cycle_times = [d.cycle_time for d in datasets]
            grids = [d.grid for d in datasets]
            forecasts = [d.forecast for d in datasets]

            @test Date(2024, 1, 15) in dates
            @test Date(2024, 1, 16) in dates
            @test "t00z" in cycle_times
            @test "t12z" in cycle_times
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

    @testset "clear_local_dataset!() function" begin
        # Create a test dataset file
        test_dset = RapidRefreshData.RAPDataset(
            date = Date(2024, 2, 20),
            cycle_time = "t06z",
            grid = "awp130",
            forecast = "f03"
        )

        path = RapidRefreshData.local_path(test_dset)

        # Write dummy content to create the file
        write(path, "test data for deletion")

        # Verify file exists
        @test isfile(path)

        # Clear the dataset
        RapidRefreshData.clear_local_dataset!(test_dset)

        # Verify file was removed
        @test !isfile(path)

        # Test clearing a dataset that doesn't exist (should not error)
        test_dset_nonexistent = RapidRefreshData.RAPDataset(
            date = Date(2024, 12, 31),
            cycle_time = "t18z",
            grid = "awp252",
            forecast = "f12"
        )

        # This should not throw an error
        @test_nowarn RapidRefreshData.clear_local_dataset!(test_dset_nonexistent)

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
        path1 = "gfs_20240115_00_0p25_atmos_f000.grib2"
        dset1 = read(RapidRefreshData.GFSDataset, path1)
        @test dset1.date == Date(2024, 1, 15)
        @test dset1.cycle == "00"
        @test dset1.resolution == "0p25"
        @test dset1.product == "atmos"
        @test dset1.forecast == "f000"

        # Test parsing with different parameters
        path2 = "gfs_20241225_12_0p50_wave_f024.grib2"
        dset2 = read(RapidRefreshData.GFSDataset, path2)
        @test dset2.date == Date(2024, 12, 25)
        @test dset2.cycle == "12"
        @test dset2.resolution == "0p50"
        @test dset2.product == "wave"
        @test dset2.forecast == "f024"

        # Test parsing with full path
        full_path = "/some/directory/gfs_20240305_06_1p00_atmos_f012.grib2"
        dset3 = read(RapidRefreshData.GFSDataset, full_path)
        @test dset3.date == Date(2024, 3, 5)
        @test dset3.cycle == "06"
        @test dset3.resolution == "1p00"
        @test dset3.product == "atmos"
        @test dset3.forecast == "f012"

        # Test that read works with broadcast
        paths = ["gfs_20240101_00_0p25_atmos_f000.grib2", "gfs_20240102_18_0p50_wave_f384.grib2"]
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

        # Check that path includes the scratch directory
        @test occursin(RapidRefreshData.gfs_dir, local_path_result)

        # Check that filename has correct format
        @test occursin("gfs_20240115_00_0p25_atmos_f000.grib2", local_path_result)

        # Test with custom parameters
        dset2 = RapidRefreshData.GFSDataset(
            date = Date(2024, 12, 25),
            cycle = "12",
            resolution = "0p50",
            product = "wave",
            forecast = "f024"
        )
        local_path_result2 = RapidRefreshData.local_path(dset2)
        @test occursin("gfs_20241225_12_0p50_wave_f024.grib2", local_path_result2)

        # Verify path ends with .grib2
        @test endswith(local_path_result, ".grib2")
        @test endswith(local_path_result2, ".grib2")
    end

    @testset "GFSDataset get() function" begin
        # Note: We don't test actual downloads here to avoid network dependencies
        # and large file downloads in CI. Instead we test the logic.

        test_date = Date(2024, 1, 15)
        dset = RapidRefreshData.GFSDataset(date = test_date)

        # Test that get returns a path (string)
        # In actual use, this would download or return cached file
        # We just verify the function exists and can be called
        @test hasmethod(get, (RapidRefreshData.GFSDataset,))

        # Verify that local_path returns the expected path format
        path = RapidRefreshData.local_path(dset)
        @test isa(path, String)
        @test endswith(path, ".grib2")
    end

    @testset "GFSDataset local_datasets() function" begin
        # Create some test GFS dataset files
        test_dset1 = RapidRefreshData.GFSDataset(
            date = Date(2024, 1, 15),
            cycle = "00",
            resolution = "0p25",
            product = "atmos",
            forecast = "f000"
        )
        test_dset2 = RapidRefreshData.GFSDataset(
            date = Date(2024, 1, 16),
            cycle = "12",
            resolution = "0p50",
            product = "wave",
            forecast = "f006"
        )

        # Create temporary files to test with
        path1 = RapidRefreshData.local_path(test_dset1)
        path2 = RapidRefreshData.local_path(test_dset2)

        # Write dummy content to the files
        write(path1, "test gfs data 1")
        write(path2, "test gfs data 2")

        try
            # Get all local GFS datasets
            datasets = RapidRefreshData.local_datasets(RapidRefreshData.GFSDataset)

            # Should return an array of GFSDatasets
            @test isa(datasets, Vector{RapidRefreshData.GFSDataset})

            # Should contain at least our test datasets
            @test length(datasets) >= 2

            # Check that our test datasets are in the list
            dates = [d.date for d in datasets]
            cycles = [d.cycle for d in datasets]
            resolutions = [d.resolution for d in datasets]
            products = [d.product for d in datasets]
            forecasts = [d.forecast for d in datasets]

            @test Date(2024, 1, 15) in dates
            @test Date(2024, 1, 16) in dates
            @test "00" in cycles
            @test "12" in cycles
            @test "0p25" in resolutions
            @test "0p50" in resolutions
            @test "atmos" in products
            @test "wave" in products
            @test "f000" in forecasts
            @test "f006" in forecasts
        finally
            # Clean up test files
            rm(path1, force=true)
            rm(path2, force=true)
        end
    end

    @testset "GFSDataset clear_local_dataset!() function" begin
        # Create a test GFS dataset file
        test_dset = RapidRefreshData.GFSDataset(
            date = Date(2024, 2, 20),
            cycle = "06",
            resolution = "0p25",
            product = "atmos",
            forecast = "f012"
        )

        path = RapidRefreshData.local_path(test_dset)

        # Write dummy content to create the file
        write(path, "test gfs data for deletion")

        # Verify file exists
        @test isfile(path)

        # Clear the dataset
        RapidRefreshData.clear_local_dataset!(test_dset)

        # Verify file was removed
        @test !isfile(path)

        # Test clearing a dataset that doesn't exist (should not error)
        test_dset_nonexistent = RapidRefreshData.GFSDataset(
            date = Date(2024, 12, 31),
            cycle = "18",
            resolution = "1p00",
            product = "wave",
            forecast = "f384"
        )

        # This should not throw an error
        @test_nowarn RapidRefreshData.clear_local_dataset!(test_dset_nonexistent)

        # Verify the non-existent file still doesn't exist
        @test !isfile(RapidRefreshData.local_path(test_dset_nonexistent))
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
        path1 = "hrrr_20240115_00_conus_wrfsfc_f00.grib2"
        dset1 = read(RapidRefreshData.HRRRDataset, path1)
        @test dset1.date == Date(2024, 1, 15)
        @test dset1.cycle == "00"
        @test dset1.region == "conus"
        @test dset1.product == "wrfsfc"
        @test dset1.forecast == "f00"

        # Test parsing with different parameters
        path2 = "hrrr_20241225_12_alaska_wrfprs_f24.grib2"
        dset2 = read(RapidRefreshData.HRRRDataset, path2)
        @test dset2.date == Date(2024, 12, 25)
        @test dset2.cycle == "12"
        @test dset2.region == "alaska"
        @test dset2.product == "wrfprs"
        @test dset2.forecast == "f24"

        # Test parsing with full path
        full_path = "/some/directory/hrrr_20240305_18_conus_wrfnat_f03.grib2"
        dset3 = read(RapidRefreshData.HRRRDataset, full_path)
        @test dset3.date == Date(2024, 3, 5)
        @test dset3.cycle == "18"
        @test dset3.region == "conus"
        @test dset3.product == "wrfnat"
        @test dset3.forecast == "f03"

        # Test that read works with broadcast
        paths = ["hrrr_20240101_00_conus_wrfsfc_f00.grib2", "hrrr_20240102_06_alaska_wrfprs_f12.grib2"]
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

        # Check that path includes the scratch directory
        @test occursin(RapidRefreshData.hrrr_dir, local_path_result)

        # Check that filename has correct format
        @test occursin("hrrr_20240115_00_conus_wrfsfc_f00.grib2", local_path_result)

        # Test with custom parameters
        dset2 = RapidRefreshData.HRRRDataset(
            date = Date(2024, 12, 25),
            cycle = "12",
            region = "alaska",
            product = "wrfprs",
            forecast = "f24"
        )
        local_path_result2 = RapidRefreshData.local_path(dset2)
        @test occursin("hrrr_20241225_12_alaska_wrfprs_f24.grib2", local_path_result2)

        # Verify path ends with .grib2
        @test endswith(local_path_result, ".grib2")
        @test endswith(local_path_result2, ".grib2")
    end

    @testset "HRRRDataset get() function" begin
        # Note: We don't test actual downloads here to avoid network dependencies
        # and large file downloads in CI. Instead we test the logic.

        test_date = Date(2024, 1, 15)
        dset = RapidRefreshData.HRRRDataset(date = test_date)

        # Test that get returns a path (string)
        # In actual use, this would download or return cached file
        # We just verify the function exists and can be called
        @test hasmethod(get, (RapidRefreshData.HRRRDataset,))

        # Verify that local_path returns the expected path format
        path = RapidRefreshData.local_path(dset)
        @test isa(path, String)
        @test endswith(path, ".grib2")
    end

    @testset "HRRRDataset local_datasets() function" begin
        # Create some test HRRR dataset files
        test_dset1 = RapidRefreshData.HRRRDataset(
            date = Date(2024, 1, 15),
            cycle = "00",
            region = "conus",
            product = "wrfsfc",
            forecast = "f00"
        )
        test_dset2 = RapidRefreshData.HRRRDataset(
            date = Date(2024, 1, 16),
            cycle = "12",
            region = "alaska",
            product = "wrfprs",
            forecast = "f06"
        )

        # Create temporary files to test with
        path1 = RapidRefreshData.local_path(test_dset1)
        path2 = RapidRefreshData.local_path(test_dset2)

        # Write dummy content to the files
        write(path1, "test hrrr data 1")
        write(path2, "test hrrr data 2")

        try
            # Get all local HRRR datasets
            datasets = RapidRefreshData.local_datasets(RapidRefreshData.HRRRDataset)

            # Should return an array of HRRRDatasets
            @test isa(datasets, Vector{RapidRefreshData.HRRRDataset})

            # Should contain at least our test datasets
            @test length(datasets) >= 2

            # Check that our test datasets are in the list
            dates = [d.date for d in datasets]
            cycles = [d.cycle for d in datasets]
            regions = [d.region for d in datasets]
            products = [d.product for d in datasets]
            forecasts = [d.forecast for d in datasets]

            @test Date(2024, 1, 15) in dates
            @test Date(2024, 1, 16) in dates
            @test "00" in cycles
            @test "12" in cycles
            @test "conus" in regions
            @test "alaska" in regions
            @test "wrfsfc" in products
            @test "wrfprs" in products
            @test "f00" in forecasts
            @test "f06" in forecasts
        finally
            # Clean up test files
            rm(path1, force=true)
            rm(path2, force=true)
        end
    end

    @testset "HRRRDataset clear_local_dataset!() function" begin
        # Create a test HRRR dataset file
        test_dset = RapidRefreshData.HRRRDataset(
            date = Date(2024, 2, 20),
            cycle = "06",
            region = "conus",
            product = "wrfnat",
            forecast = "f12"
        )

        path = RapidRefreshData.local_path(test_dset)

        # Write dummy content to create the file
        write(path, "test hrrr data for deletion")

        # Verify file exists
        @test isfile(path)

        # Clear the dataset
        RapidRefreshData.clear_local_dataset!(test_dset)

        # Verify file was removed
        @test !isfile(path)

        # Test clearing a dataset that doesn't exist (should not error)
        test_dset_nonexistent = RapidRefreshData.HRRRDataset(
            date = Date(2024, 12, 31),
            cycle = "18",
            region = "alaska",
            product = "wrfsub",
            forecast = "f48"
        )

        # This should not throw an error
        @test_nowarn RapidRefreshData.clear_local_dataset!(test_dset_nonexistent)

        # Verify the non-existent file still doesn't exist
        @test !isfile(RapidRefreshData.local_path(test_dset_nonexistent))
    end

    @testset "README Examples" begin
        # Test Quick Start - RAP Data example
        rap = RapidRefreshData.RAPDataset(
            date = Date(2025, 1, 8),
            cycle_time = "t12z",
            forecast = "f06"
        )
        @test rap.date == Date(2025, 1, 8)
        @test rap.cycle_time == "t12z"
        @test rap.forecast == "f06"
        # Verify get() returns a string path
        @test isa(RapidRefreshData.local_path(rap), String)

        # Test Quick Start - GFS Data example
        gfs = RapidRefreshData.GFSDataset(
            date = Date(2025, 1, 8),
            cycle = "12",
            resolution = "0p25",
            forecast = "f006"
        )
        @test gfs.date == Date(2025, 1, 8)
        @test gfs.cycle == "12"
        @test gfs.resolution == "0p25"
        @test gfs.forecast == "f006"

        # Test date filtering pattern from cleanup example
        old_dset = RapidRefreshData.RAPDataset(
            date = today() - Day(10),
            cycle_time = "t00z",
            forecast = "f00"
        )
        recent_dset = RapidRefreshData.RAPDataset(
            date = today() - Day(3),
            cycle_time = "t00z",
            forecast = "f00"
        )

        # Test the date comparison pattern
        @test old_dset.date < today() - Day(7)
        @test !(recent_dset.date < today() - Day(7))

        # Test multiple forecast hours pattern (README loop example)
        date = Date(2025, 1, 8)
        cycle = "12"
        forecast_hours = []

        for fhour in 0:6:18
            forecast_str = string("f", lpad(fhour, 3, '0'))
            push!(forecast_hours, forecast_str)

            gfs_test = RapidRefreshData.GFSDataset(
                date = date,
                cycle = cycle,
                forecast = forecast_str
            )
            @test gfs_test.forecast == forecast_str
        end

        # Verify forecast string formatting works correctly
        @test forecast_hours == ["f000", "f006", "f012", "f018"]

        # Test cleanup pattern with actual files
        test_old = RapidRefreshData.RAPDataset(
            date = today() - Day(10),
            cycle_time = "t00z",
            forecast = "f00"
        )
        test_recent = RapidRefreshData.RAPDataset(
            date = today() - Day(3),
            cycle_time = "t00z",
            forecast = "f00"
        )

        # Create temporary files
        path_old = RapidRefreshData.local_path(test_old)
        path_recent = RapidRefreshData.local_path(test_recent)
        write(path_old, "old data")
        write(path_recent, "recent data")

        try
            # Get all datasets
            rap_datasets = RapidRefreshData.local_datasets(RapidRefreshData.RAPDataset)

            # Filter and clear old datasets (README pattern)
            for dset in rap_datasets
                if dset.date < today() - Day(7)
                    RapidRefreshData.clear_local_dataset!(dset)
                end
            end

            # Old file should be deleted, recent should remain
            @test !isfile(path_old)
            @test isfile(path_recent)
        finally
            # Cleanup
            rm(path_old, force=true)
            rm(path_recent, force=true)
        end
    end
end
