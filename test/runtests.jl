using RapidRefreshData
using Test
using Dates

@testset "RapidRefreshData.jl" begin
    @testset "Dataset construction" begin
        # Test default construction
        dset_default = RapidRefreshData.Dataset()
        @test dset_default.date == today()
        @test dset_default.cycle_time == "t00z"
        @test dset_default.grid == "awp130"
        @test dset_default.product == "pgrb"
        @test dset_default.forecast == "f00"

        # Test custom construction with keyword arguments
        test_date = Date(2024, 1, 15)
        dset_custom = RapidRefreshData.Dataset(
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
        dset_partial = RapidRefreshData.Dataset(cycle_time = "t18z", forecast = "f03")
        @test dset_partial.date == today()
        @test dset_partial.cycle_time == "t18z"
        @test dset_partial.grid == "awp130"
        @test dset_partial.forecast == "f03"
    end

    @testset "url() function" begin
        # Test URL generation with default dataset
        test_date = Date(2024, 1, 15)
        dset = RapidRefreshData.Dataset(date = test_date)
        expected_url = "https://noaa-rap-pds.s3.amazonaws.com/rap.20240115/rap.t00z.awp130pgrbf00.grib2"
        @test RapidRefreshData.url(dset) == expected_url

        # Test URL generation with custom parameters
        dset2 = RapidRefreshData.Dataset(
            date = Date(2024, 12, 25),
            cycle_time = "t12z",
            grid = "awp252",
            forecast = "f06"
        )
        expected_url2 = "https://noaa-rap-pds.s3.amazonaws.com/rap.20241225/rap.t12z.awp252pgrbf06.grib2"
        @test RapidRefreshData.url(dset2) == expected_url2

        # Test with different date formats
        dset3 = RapidRefreshData.Dataset(date = Date(2024, 3, 5))
        expected_url3 = "https://noaa-rap-pds.s3.amazonaws.com/rap.20240305/rap.t00z.awp130pgrbf00.grib2"
        @test RapidRefreshData.url(dset3) == expected_url3
    end

    @testset "local_path() function" begin
        # Test local path generation
        test_date = Date(2024, 1, 15)
        dset = RapidRefreshData.Dataset(date = test_date)
        local_path_result = RapidRefreshData.local_path(dset)

        # Check that path includes the scratch directory
        @test occursin(RapidRefreshData.dir, local_path_result)

        # Check that filename has correct format
        @test occursin("20240115_t00z_awp130_f00.grib2", local_path_result)

        # Test with custom parameters
        dset2 = RapidRefreshData.Dataset(
            date = Date(2024, 12, 25),
            cycle_time = "t12z",
            grid = "awp252",
            forecast = "f06"
        )
        local_path_result2 = RapidRefreshData.local_path(dset2)
        @test occursin("20241225_t12z_awp252_f06.grib2", local_path_result2)

        # Verify path ends with .grib2
        @test endswith(local_path_result, ".grib2")
        @test endswith(local_path_result2, ".grib2")
    end

    @testset "Scratch directory initialization" begin
        # Test that scratch directory is initialized
        @test RapidRefreshData.dir != ""
        @test isdir(RapidRefreshData.dir)
    end

    @testset "download() function" begin
        # Note: We don't test actual downloads here to avoid network dependencies
        # and large file downloads in CI. Instead we test the logic.

        test_date = Date(2024, 1, 15)
        dset = RapidRefreshData.Dataset(date = test_date)

        # Test that download returns a path (string)
        # In actual use, this would download or return cached file
        # We just verify the function exists and can be called
        @test isdefined(RapidRefreshData, :download)
        @test hasmethod(download, (RapidRefreshData.Dataset,))

        # Verify that local_path returns the expected path format
        path = RapidRefreshData.local_path(dset)
        @test isa(path, String)
        @test endswith(path, ".grib2")
    end
end
