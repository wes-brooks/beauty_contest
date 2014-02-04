predicted = vector()
actual = vector()
threshold = vector()
fold = vector()

for (f in files) {
  raw = scan(file, 'character', sep='\n')
  i = grep("^# Site = ([^\\w])", raw)
  if (i) {
    site = str_match(raw, "^# Site = ([^\\w]+$)")[i,2]
  }
  
  i = grep("^# Method = ([[:alnum:][:punct:]])", raw)
  if (i) {
      method = str_match(raw, "^# Method = ([[:alnum:][:punct:]]+$)")[i,2]
  }
  
  i = grep("^\\$predicted$", raw)
  if (i) {
      pred = as.numeric(raw[i+2])
  }
  
  i = grep("^\\$actual$", raw)
  if (i) {
      act = as.numeric(strsplit(raw[i+1], " ")[[1]][2])
  }
}
