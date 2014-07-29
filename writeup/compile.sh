#! /bin/bash
mkdir -p latex

lyx --export pdflatex Beauty_Contest.lyx

xelatex -output-directory=latex Beauty_Contest
bibtex Beauty_Contest
xelatex -output-directory=latex Beauty_Contest
xelatex -output-directory=latex Beauty_Contest

mv latex/Beauty_Contest.pdf ./