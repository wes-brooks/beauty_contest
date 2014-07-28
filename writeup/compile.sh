#! /bin/bash
mkdir -p aux

lyx --export pdflatex Beauty_Contest.lyx

xelatex -output-directory=aux Beauty_Contest
bibtex Beauty_Contest
xelatex -output-directory=aux Beauty_Contest
xelatex -output-directory=aux Beauty_Contest

mv aux/Beauty_Contest.pdf ./