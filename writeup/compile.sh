#! /bin/bash
mkdir -p aux

lyx --export pdflatex Beauty_Contest.lyx

xelatex -output-directory=aux-latex Beauty_Contest
bibtex Beauty_Contest
xelatex -output-directory=aux-latex Beauty_Contest
xelatex -output-directory=aux-latex Beauty_Contest

mv aux-latex/Beauty_Contest.pdf ./