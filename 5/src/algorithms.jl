#Agnieszka Kurzajewska
# 244994

module Algorithms

using SparseArrays
using LinearAlgebra

function readData(filePath::String)
	open(filePath) do file
		line = split(readline(file))
		n = parse(Int64, line[1])
		l = parse(Int64, line[2])
		matrixElements = n*l + 3*(n-l)
		A = spzeros(Float64, n, n)
		iterations = 1
		while !eof(file)
			line = split(readline(file))
			i = parse(Int64, line[1])
			j = parse(Int64, line[2])
			value = parse(Float64, line[3])
			A[j, i] = value
			iterations += 1
		end
		return (A, n, l)
	end
end

function readVectorfromRight(filePath::String)
	open(filePath) do file
		n = parse(Int64, readline(file))
		b = Array{Float64}(undef, n)
		i = 0
		while !eof(file)
			i += 1
			b[i] = parse(Float64, readline(file))
		end
		return b
	end
end

function backwardInChoiceSubstitution(A::SparseMatrixCSC{Float64, Int64}, p::Vector{Int64}, l:: Int64, n::Int64, b::Vector{Float64})
		x = Array{Float64}(undef, n)
		for i in n : -1 : 1
			sum = 0.0
			lastColumn = convert(Int64, min(2*l + l*floor((p[i]+1)/l), n))
			for j in i + 1 : lastColumn	
				sum = sum +  A[j,p[i]] * x[j]
			end
			x[i] = (b[p[i]] - sum) / A[i, p[i]]
		end
		return x
end

function backwardSubstitution(A::SparseMatrixCSC{Float64, Int64}, l:: Int64, n::Int64, b::Vector{Float64})
	x = Array{Float64}(undef, n)
	for i in n : -1 : 1
		sum = 0.0
		lastColumn = min(n, i + l)
		for j in i + 1 : lastColumn
			sum = sum + A[j, i] * x[j]
		end
		x[i] = (b[i] - sum) / A[i, i]
	end
	return x
end

function calculateGaussWithoutChoice(A::SparseMatrixCSC{Float64, Int64}, n::Int64, l::Int64, b::Vector{Float64})
	for k in 1 : n-1
		lastRow = convert(Int64, min(l + l * floor((k+1) / l), n))
		lastColumn = convert(Int64, min(k + l, n))
		for i in k + 1 : lastRow
			if abs(A[k,k]) < eps(Float64)
				error("Współczynnik na przekątnej równy 0.")
			end
			z = A[k, i] / A[k, k]
			A[k, i] = 0
			for j in k + 1 : lastColumn
				A[j, i] = A[j, i] - z * A[j, k]
			end
			b[i] = b[i] - z * b[k]
		end
	end
	x = backwardSubstitution(A, l, n, b)
	return x;
end

function calculateGaussWithChoice(A::SparseMatrixCSC{Float64, Int64}, n::Int64, l::Int64, b::Vector{Float64})
	p = collect(1:n)
	for k in 1:n - 1
		lastRow = convert(Int64, min(l + l * floor((k+1) / l), n))
		lastColumn = convert(Int64, min(2*l + l * floor((k+1) / l), n))
		for i in k + 1 : lastRow
			maxRow = k
			max = abs(A[k,p[k]])
			for x in i : lastRow
				if (abs(A[k,p[x]]) > max)
					maxRow = x;
					max = abs(A[k,p[x]])
				end
			end
			if (abs(max) < eps(Float64))
				error("Współczynnik na przekątnej równy 0.")
			end
			p[k], p[maxRow] = p[maxRow], p[k]
			z = A[k,p[i]] / A[k,p[k]]
			A[k,p[i]] = 0
			for j in k + 1 : lastColumn
				A[j,p[i]] = A[j,p[i]] - z * A[j,p[k]]
			end
			b[p[i]] = b[p[i]] - z * b[p[k]]
		end
	end
	x = backwardInChoiceSubstitution(A, p, l, n, b)
	return x;
end

function calculateLUWithoutChoice(A::SparseMatrixCSC{Float64, Int64}, n::Int64, l::Int64, b::Vector{Float64})
	for k in 1 : n-1
		lastRow = convert(Int64, min(l + l * floor((k+1) / l), n))
		lastColumn = convert(Int64, min(k + l, n))
		for i in k + 1 : lastRow
			if abs(A[k,k]) < eps(Float64)
				error("Współczynnik na przekątnej równy 0.")
			end
			z = A[k, i] / A[k, k]
			A[k, i] = z
			for j in k + 1 : lastColumn
				A[j, i] = A[j, i] - z * A[j, k]
			end
			b[i] = b[i] - z * b[k]
		end
	end
	x = backwardSubstitution(A, l, n, b)
	return x;
end

function calculateLUWithChoice(A::SparseMatrixCSC{Float64, Int64}, n::Int64, l::Int64, b::Vector{Float64})

	p = collect(1:n)
	for k in 1:n - 1
		lastRow = convert(Int64, min(l + l * floor((k+1) / l), n))
		lastColumn = convert(Int64, min(2*l + l * floor((k+1) / l), n))
		for i in k + 1 : lastRow
			maxRow = k
			max = abs(A[k,p[k]])
			for x in i : lastRow
				if (abs(A[k,p[x]]) > max)
					maxRow = x;
					max = abs(A[k,p[x]])
				end
			end
			if (abs(max) < eps(Float64))
				error("Współczynnik na przekątnej równy 0.")
			end
			p[k], p[maxRow] = p[maxRow], p[k]
			z = A[k,p[i]] / A[k,p[k]]
			A[k,p[i]] = z
			for j in k + 1 : lastColumn
				A[j,p[i]] = A[j,p[i]] - z * A[j,p[k]]
			end
			b[p[i]] = b[p[i]] - z * b[p[k]]
		end
	end

	x = backwardInChoiceSubstitution(A, p, l, n, b)
	return x;
end

function saveResultToFile(filePath::String, x::Vector{Float64}, n::Int64)
	open(filePath, "w") do file
			relativeError = norm(ones(n) - x) / norm(x)
			println(file, relativeError)
		for i in 1 : n
			println(file, x[i])
		end
	end
end

export readData, readVectorfromRight, saveResultToFile,
calculateGaussWithoutChoice, calculateGaussWithChoice, calculateLUWithoutChoice, calculateLUWithChoice

end
