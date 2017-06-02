#!/bin/bash

generate_perf() {
gpumodel=$1
ngpus=$2
op=$3

result=results/$gpumodel/$op.$ngpus

mkdir -p results/$gpumodel/
echo "Running test/perf/${op}_perf -g $ngpus ..."
#test/perf/${op}_perf -g $ngpus -b 5000 -e 50000 -i 5000 > $result.out
test/perf/${op}_perf -g $ngpus -b 5000 -e 995000 -i 15000 -c 0 -w 10 -n 20 | tee $result.out
test/perf/${op}_perf -g $ngpus -b 1000000 -e 19000000 -i 1000000 -c 0 -w 5 -n 5 | tee -a $result.out
test/perf/${op}_perf -g $ngpus -b 20000000 -e 400000000 -i 20000000 -c 0 -w 1 -n 1 | tee -a $result.out
}

generate_plot() {
gpumodel=$1
ngpus=$2
op=$3
busbwcol=$4

result=results/$gpumodel/$op.$ngpus

cat $result.out | grep float | awk "{ print \$1,\$$busbwcol; }" > $result.values

cat > $result.plot << EOF
set term png
set output "$result.png"
plot "$result.values" using 1:2 with lines, \
     "ref/1.6.1/$gpumodel/$op.$ngpus.values" using 1:2 with lines, \
     "ref/2.0.2/$gpumodel/$op.$ngpus.values" using 1:2 with lines
replot
EOF

gnuplot $result.plot
}

perf_ngpu_loop() {
gpumodel=$1
maxgpu=$2
op=$3
for ngpus in `seq 2 2 $maxgpu`; do
  generate_perf $gpumodel $ngpus $op
done
}

plot_ngpu_loop() {
gpumodel=$1
maxgpu=$2
op=$3
busbwcol=$4
for ngpus in `seq 2 2 $maxgpu`; do
  generate_plot $gpumodel $ngpus $op $busbwcol
done
}

gpumodel=$1
maxgpu=$2

if [ "$maxgpu" == "" ]; then
  echo "Usage : $0 <gpumodel> <maxgpus>"
  exit 1
fi

perf_ngpu_loop $gpumodel $maxgpu reduce
perf_ngpu_loop $gpumodel $maxgpu broadcast
perf_ngpu_loop $gpumodel $maxgpu all_reduce
perf_ngpu_loop $gpumodel $maxgpu all_gather
perf_ngpu_loop $gpumodel $maxgpu reduce_scatter
