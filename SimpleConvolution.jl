@printf "adding 2 processes (Workers)\n"
addprocs(2)

@printf "using DistributedArrays package\n"
using DistributedArrays

@printf "define at all processes (Master and Workers) the ImageData type\n"
@everywhere type ImageData
	raw_data # polSAR image data itself
	processed_data
end



@printf "create a DistributedArray with image data\n"
@printf "DistributedArray data is automatic stored at Workers\n"
@printf "remark: CloudArray allows to create DistributedArrays from files\n"
darray = distribute(array)

@printf "for all workers\n"
for w in workers()
	# iterates over darray data stored at Worker w (this is done remotely, at Worker w)
	@spawnat w for i=2:length(localpart(darray))-1 # localpart(darray) means the darray data stored at Worker w
		# calculate a simple convolution (BUGFIX address overlap areas)
		localpart(darray)[i].processed_data = ( localpart(darray)[i-1].raw_data + localpart(darray)[i].raw_data + localpart(darray)[i+1].raw_data ) / 3
	end
end

@printf "printing the image and the convolution\n"
for i=1:length(darray)
	@show darray[i]
end 

#@printf "sleeping 10 secs to wait Workers finish their jobs...\n"
#sleep(10)