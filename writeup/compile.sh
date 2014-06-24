#! /bin/bash

lyx --export pdflatex Beauty_Contest.lyx
pdflatex Beauty_Contest
bibtex Beauty_Contest
pdflatex Beauty_Contest
