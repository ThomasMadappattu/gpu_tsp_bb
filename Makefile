all: tsp



tsp: tsp_single.cu driver.cu queue.cu
	nvcc  -g -arch=compute_20 $^ -o $@


clean:
	rm -f *.o
	rm tsp
