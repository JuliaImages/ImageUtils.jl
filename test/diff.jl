@testset "fdiff" begin
    @testset "API" begin
        # fdiff! works the same as fdiff
        mat_in = rand(3, 3, 3)
        mat_out = similar(mat_in)
        fdiff!(mat_out, mat_in, dims = 2)
        @test mat_out == fdiff(mat_in, dims = 2)

        mat_in = rand(3, 3, 3)
        mat_out = similar(mat_in)
        fdiff!(mat_out, mat_in, dims = 3, rev=true)
        @test mat_out == fdiff(mat_in, dims = 3, rev=true)
    end

    @testset "NumericalTests" begin
        a = reshape(collect(1:9), 3, 3)
        b_fd_1 = [1 1 1; 1 1 1; -2 -2 -2]
        b_fd_2 = [3 3 -6; 3 3 -6; 3 3 -6]
        b_bd_1 = [2 2 2; -1 -1 -1; -1 -1 -1]
        b_bd_2 = [6 -3 -3; 6 -3 -3; 6 -3 -3]
        out = similar(a)

        @test fdiff(a, dims = 1) == b_fd_1
        @test fdiff(a, dims = 2) == b_fd_2
        @test fdiff(a, dims = 1, rev=true) == b_bd_1
        @test fdiff(a, dims = 2, rev=true) == b_bd_2
        fdiff!(out, a, dims = 1)
        @test out == b_fd_1
        fdiff!(out, a, dims = 2)
        @test out == b_fd_2
        fdiff!(out, a, dims = 1, rev=true)
        @test out == b_bd_1
        fdiff!(out, a, dims = 2, rev=true)
        @test out == b_bd_2

        # check numerical results with base implementation
        drop_last_slice(X, dims) = collect(StackView(collect(eachslice(X, dims=dims))[1:end-1]..., dims=dims))
        function drop_last_slice(X::AbstractVector, dims)
            @assert dims==1
            X[1:end-1]
        end
        drop_first_slice(X, dims) = collect(StackView(collect(eachslice(X, dims=dims))[2:end]..., dims=dims))
        function drop_first_slice(X::AbstractVector, dims)
            @assert dims==1
            X[2:end]
        end

        for N in 1:3
            sz = ntuple(_->5, N)
            A = rand(sz...)
            A_out = similar(A)
            
            for dims = 1:N
                out_base = diff(A; dims=dims)
                out = fdiff(A; dims=dims)
                @test out_base == drop_last_slice(out, dims)

                out_base = reverse(diff(reverse(A; dims=dims); dims=dims); dims=dims)
                out = fdiff(A; dims=dims, rev=true)
                @test out_base == drop_first_slice(out, dims)
            end
        end
    end

    @testset "OffsetArrays" begin
        A = OffsetArray(rand(3, 3), -1, -1)
        A_out = fdiff(A, dims=1)
        @test axes(A_out) == (0:2, 0:2)
        @test A_out.parent == fdiff(parent(A), dims=1)

        A = OffsetArray(rand(3, 3), -1, -1)
        A_out = fdiff(A, dims=1, rev=true)
        @test axes(A_out) == (0:2, 0:2)
        @test A_out.parent == fdiff(parent(A), dims=1, rev=true)
    end
end