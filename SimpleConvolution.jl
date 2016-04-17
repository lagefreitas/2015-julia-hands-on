# Example of a simple convolution operation using DistributedArrays.
# Author: André Lage-Freitas

n_of_workers=4
darray_size=10

# removing previous Workers if they exist
if nprocs() > 1
	rmprocs(workers())
end

println("adding $n_of_workers Workers")
addprocs(n_of_workers)
@show workers()

# using DistributedArrays package
using DistributedArrays

println("defining at all processes (Master and Workers) the ImageData type")
@everywhere type ImageData
    # typing to Float64 is not necessary but increase performance
    raw_data::Float64 # polSAR image data itself
    processed_data::Float64
end

println("creating a DistributedArray with a mock image")
println("  create a $(darray_size)-dimension mock image by using ImageData")
array = []
for i=1:10
	push!(array, ImageData(rand(), 0.0))
end
println("  turning the array into a DArray")
# DistributedArray data is automatic created and stored at Workers
# remark: CloudArray allows to create DistributedArrays from files
#darray = dfill(ImageData(rand(), 0.0), darray_size) # dimension is darray_size
darray = distribute(array)

# for all workers
for w in workers()
    # iterates over darray data stored at Worker w (this is done remotely, at Worker w)
    @spawnat w for i=2:length(localpart(darray))-1 # localpart(darray) means the darray data stored at Worker w
        # calculate a simple convolution (BUGFIX address overlap areas)
        localpart(darray)[i].processed_data = ( localpart(darray)[i-1].raw_data + localpart(darray)[i].raw_data + localpart(darray)[i+1].raw_data ) / 3
    end
end

println("Printing the image and its convolution")
for i=1:length(darray) @show darray[i]; end 
