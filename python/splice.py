import sys
import os

cluster = str(sys.argv[1])

if len(sys.argv)>2: location = sys.argv[2]
else: location = os.getcwd()
files = os.listdir(location)

for filename in files:
    if (cluster in filename) and (os.path.isfile(os.path.join(location, filename))):
        try:
            [cluster, process, site, method, out] = filename.split(".")
            infile = open(os.path.join(location, filename), 'r')
            lines = infile.readlines()
            infile.close()
            
            [seed] = [line.split(" ")[-1].strip() for line in lines if "Seed" in line]
            try:
                [tpos] = [line.split(" ")[-1].strip() for line in lines if "aggregate.tpos" in line]
                [tneg] = [line.split(" ")[-1].strip() for line in lines if "aggregate.tneg" in line]
                [fpos] = [line.split(" ")[-1].strip() for line in lines if "aggregate.fpos" in line]
                [fneg] = [line.split(" ")[-1].strip() for line in lines if "aggregate.fneg" in line]
                [area] = [line.split(" ")[-1].strip() for line in lines if "Area under ROC" in line]
            except ValueError:
                [area, tpos, tneg, fpos, fneg] = ['na' for k in range(5)]
            
            outfile = os.path.join(location, ".".join([cluster, site, method]))
            if not os.path.isfile(outfile):
                outfile = open(outfile, 'w')
                outfile.write("seed,area,tpos,tneg,fpos,fneg\n")
            else:
                outfile = open(outfile, 'a')

            outfile.write(",".join([seed,area,tpos,tneg,fpos,fneg]) + "\n")
            outfile.close()
        except: pass

